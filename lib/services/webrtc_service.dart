import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/operation/operation.dart';

class WebRTCService {
  final String userId;
  final Function(String peerId, Operation operation)? onOperationReceived;
  final Function(String peerId)? onPeerConnected;
  final Function(String peerId)? onPeerDisconnected;
  final Function(String peerId, MediaStream stream)? onRemoteAudioStream;

  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RTCDataChannel> _dataChannels = {};
  final Map<String, List<RTCIceCandidate>> _pendingIceCandidates = {};
  final Map<String, bool> _makingOffer = {};
  final Map<String, bool> _ignoreOffer = {};

  // Audio streaming
  MediaStream? _localAudioStream;
  final Map<String, MediaStream> _remoteAudioStreams = {};
  bool _isAudioEnabled = false;

  WebRTCService({
    required this.userId,
    this.onOperationReceived,
    this.onPeerConnected,
    this.onPeerDisconnected,
    this.onRemoteAudioStream,
  });

  bool _isPolite(String peerId) {
    // Use userId comparison to determine polite peer (stable ordering)
    return userId.compareTo(peerId) > 0;
  }

  Map<String, dynamic> _getIceConfiguration() {
    return {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {
          'urls': [
            'turn:openrelay.metered.ca:80',
            'turn:openrelay.metered.ca:443',
          ],
          'username': 'openrelayproject',
          'credential': 'openrelayproject',
        },
      ],
      'iceTransportPolicy': 'all',
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
    };
  }

  Future<void> initPeerConnection(
    String peerId,
    Function(Map<String, dynamic>) onLocalDescription,
  ) async {
    debugPrint('🔗 Creating peer connection for $peerId');

    final pc = await createPeerConnection(_getIceConfiguration());
    _peerConnections[peerId] = pc;

    // Monitor connection state
    pc.onConnectionState = (state) {
      debugPrint('🔗 Peer connection state with $peerId: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        debugPrint('❌ Connection failed/disconnected with $peerId');
        onPeerDisconnected?.call(peerId);
        // Clean up audio stream
        _remoteAudioStreams[peerId]?.dispose();
        _remoteAudioStreams.remove(peerId);
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        debugPrint('✅ Connection established with $peerId');
      }
    };

    pc.onIceConnectionState = (state) {
      debugPrint('🧊 ICE connection state with $peerId: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        debugPrint('❌ ICE failed with $peerId');
      } else if (state ==
          RTCIceConnectionState.RTCIceConnectionStateConnected) {
        debugPrint('✅ ICE connected with $peerId');
      }
    };

    pc.onIceGatheringState = (state) {
      debugPrint('🔍 ICE gathering state with $peerId: $state');
    };

    // Handle incoming audio streams
    pc.onTrack = (event) {
      debugPrint('🎵 Received remote track from $peerId: ${event.track.kind}');
      if (event.track.kind == 'audio' && event.streams.isNotEmpty) {
        final stream = event.streams.first;
        _remoteAudioStreams[peerId] = stream;
        onRemoteAudioStream?.call(peerId, stream);
        debugPrint('✅ Remote audio stream stored for $peerId');
      }
    };

    // Create data channel with explicit configuration
    final dc = await pc.createDataChannel(
      'board_ops',
      RTCDataChannelInit()
        ..ordered = true
        ..protocol = 'json',
    );
    _dataChannels[peerId] = dc;
    debugPrint('📺 Created data channel for $peerId (state: ${dc.state})');

    _setupDataChannel(dc, peerId);

    // Add local audio stream if available
    if (_localAudioStream != null) {
      for (final track in _localAudioStream!.getAudioTracks()) {
        await pc.addTrack(track, _localAudioStream!);
        debugPrint('🎵 Added existing audio track to new peer $peerId');
      }
    }

    // Use perfect negotiation - track if we're making an offer
    _makingOffer[peerId] = true;
    try {
      // Create offer
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      pc.onIceCandidate = (candidate) {
        debugPrint(
          '🧊 Generated ICE candidate (offer): ${candidate.candidate?.substring(0, 50)}...',
        );
        onLocalDescription({'type': 'ice', 'candidate': candidate.toMap()});
      };

      onLocalDescription({'type': 'offer', 'sdp': offer.sdp});
    } finally {
      _makingOffer[peerId] = false;
    }
  }

  Future<void> handleSignal(
    String peerId,
    Map<String, dynamic> signal,
    Function(Map<String, dynamic>)? onLocalDescription,
  ) async {
    debugPrint('📡 Handling signal from $peerId: ${signal['type']}');

    try {
      if (signal['type'] == 'offer') {
        await _handleOffer(peerId, signal, onLocalDescription!);
      } else if (signal['type'] == 'answer') {
        await _handleAnswer(peerId, signal);
      } else if (signal['type'] == 'ice') {
        await _handleIceCandidate(peerId, signal);
      }
    } catch (e) {
      debugPrint('❌ Error handling signal from $peerId: $e');
      // Don't rethrow - just log and continue
    }
  }

  Future<void> _handleOffer(
    String peerId,
    Map<String, dynamic> signal,
    Function(Map<String, dynamic>) onLocalDescription,
  ) async {
    debugPrint('📥 Handling offer from $peerId');

    // Perfect negotiation: check for offer collision
    final offerCollision = (_makingOffer[peerId] == true);
    final readyForOffer = !offerCollision || _isPolite(peerId);
    final ignoreOffer = !readyForOffer;

    if (ignoreOffer) {
      debugPrint(
        '⚠️ Ignoring offer from $peerId (collision detected, we are impolite)',
      );
      _ignoreOffer[peerId] = true;
      return;
    }

    _ignoreOffer[peerId] = false;

    var pc = _peerConnections[peerId];
    if (pc == null) {
      pc = await createPeerConnection(_getIceConfiguration());
      _peerConnections[peerId] = pc;

      // Monitor connection state
      pc.onConnectionState = (state) {
        debugPrint('🔗 Peer connection state with $peerId: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state ==
                RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
          debugPrint('❌ Connection failed/disconnected with $peerId');
          onPeerDisconnected?.call(peerId);
        } else if (state ==
            RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          debugPrint('✅ Connection established with $peerId');
        }
      };

      pc.onIceConnectionState = (state) {
        debugPrint('🧊 ICE connection state with $peerId: $state');
        if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          debugPrint('❌ ICE failed with $peerId');
        } else if (state ==
            RTCIceConnectionState.RTCIceConnectionStateConnected) {
          debugPrint('✅ ICE connected with $peerId');
        }
      };

      pc.onIceGatheringState = (state) {
        debugPrint('🔍 ICE gathering state with $peerId: $state');
      };

      pc.onDataChannel = (channel) {
        debugPrint('📥 Data channel received from $peerId');
        _dataChannels[peerId] = channel;
        _setupDataChannel(channel, peerId);
      };

      pc.onIceCandidate = (candidate) {
        debugPrint(
          '🧊 Generated ICE candidate (answer): ${candidate.candidate?.substring(0, 50)}...',
        );
        onLocalDescription({'type': 'ice', 'candidate': candidate.toMap()});
      };
    }

    try {
      final signalingState = await pc.getSignalingState();

      // Handle offer collision with rollback
      if (signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer &&
          offerCollision) {
        if (_isPolite(peerId)) {
          // Polite peer: rollback our local offer and accept theirs
          debugPrint('🔄 Offer collision - rolling back (we are polite)');
          await pc.setLocalDescription(RTCSessionDescription('', 'rollback'));
        } else {
          // Impolite peer: ignore their offer
          debugPrint(
            '⚠️ Offer collision - ignoring remote offer (we are impolite)',
          );
          _ignoreOffer[peerId] = true;
          return;
        }
      }

      await pc.setRemoteDescription(
        RTCSessionDescription(signal['sdp'], signal['type']),
      );

      // Add any buffered ICE candidates
      final buffered = _pendingIceCandidates.remove(peerId);
      if (buffered != null && buffered.isNotEmpty) {
        debugPrint(
          '🔄 Adding ${buffered.length} buffered ICE candidates for $peerId',
        );
        for (final candidate in buffered) {
          await pc.addCandidate(candidate);
        }
      }

      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);

      onLocalDescription({'type': 'answer', 'sdp': answer.sdp});

      debugPrint('✅ Successfully handled offer from $peerId');
    } catch (e) {
      debugPrint('❌ Error processing offer from $peerId: $e');
      // On error, try to recover by recreating connection
      closePeerConnection(peerId);
    }
  }

  Future<void> _handleAnswer(String peerId, Map<String, dynamic> signal) async {
    final pc = _peerConnections[peerId];
    if (pc != null) {
      try {
        // Check if we should ignore this answer (due to collision)
        if (_ignoreOffer[peerId] == true) {
          debugPrint(
            '⚠️  Ignoring answer from $peerId (we ignored their offer)',
          );
          return;
        }

        // Check signaling state
        final signalingState = await pc.getSignalingState();
        debugPrint('📊 Current signaling state: $signalingState');

        // Only accept answer if we're in have-local-offer state
        if (signalingState !=
            RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
          debugPrint(
            '⚠️  Ignoring answer from $peerId - wrong state: $signalingState',
          );
          return;
        }

        await pc.setRemoteDescription(
          RTCSessionDescription(signal['sdp'], signal['type']),
        );

        // Add any buffered ICE candidates
        final buffered = _pendingIceCandidates.remove(peerId);
        if (buffered != null && buffered.isNotEmpty) {
          debugPrint(
            '🔄 Adding ${buffered.length} buffered ICE candidates for $peerId',
          );
          for (final candidate in buffered) {
            await pc.addCandidate(candidate);
          }
        }

        debugPrint('✅ Successfully handled answer from $peerId');
      } catch (e) {
        debugPrint('❌ Error processing answer from $peerId: $e');
      }
    }
  }

  Future<void> _handleIceCandidate(
    String peerId,
    Map<String, dynamic> signal,
  ) async {
    final pc = _peerConnections[peerId];
    if (pc != null && signal['candidate'] != null) {
      final candidate = RTCIceCandidate(
        signal['candidate']['candidate'],
        signal['candidate']['sdpMid'],
        signal['candidate']['sdpMLineIndex'],
      );

      // Always try to add candidate, buffer on error
      try {
        debugPrint('➕ Adding ICE candidate for $peerId');
        await pc.addCandidate(candidate);
      } catch (e) {
        debugPrint(
          '📦 Buffering ICE candidate for $peerId (remote desc not set yet)',
        );
        _pendingIceCandidates.putIfAbsent(peerId, () => []).add(candidate);
      }
    }
  }

  void _setupDataChannel(RTCDataChannel channel, String peerId) {
    channel.onMessage = (message) {
      try {
        final messageText = message.text;
        if (messageText.isEmpty) {
          debugPrint('⚠️  Empty message from $peerId');
          return;
        }

        debugPrint('📨 Message from $peerId (${messageText.length} bytes)');

        final data = json.decode(messageText);
        if (data is! Map<String, dynamic>) {
          debugPrint('❌ Invalid message format from $peerId');
          return;
        }

        final operation = Operation.fromJson(data);
        debugPrint(
          '✅ Parsed operation: ${operation.type.name} from ${operation.actor}',
        );
        onOperationReceived?.call(peerId, operation);
      } catch (e, stack) {
        debugPrint('❌ Error parsing operation from $peerId: $e');
        debugPrint('Stack: $stack');
      }
    };

    channel.onDataChannelState = (state) {
      debugPrint('🔄 Data channel state with $peerId: $state');
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        debugPrint('✅ Data channel OPEN with $peerId - ready to send!');
        onPeerConnected?.call(peerId);
      } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
        debugPrint('❌ Data channel CLOSED with $peerId');
        onPeerDisconnected?.call(peerId);
      } else if (state == RTCDataChannelState.RTCDataChannelConnecting) {
        debugPrint('⏳ Data channel connecting with $peerId...');
      }
    };
  }

  void sendOperation(Operation operation) {
    final message = json.encode(operation.toJson());
    final openChannels = _dataChannels.values
        .where((dc) => dc.state == RTCDataChannelState.RTCDataChannelOpen)
        .length;

    if (openChannels == 0) {
      debugPrint('⚠️  No open channels - operation not sent');
      return;
    }

    debugPrint(
      '📤 Broadcasting operation ${operation.type.name} to $openChannels/${_dataChannels.length} peers',
    );

    int successCount = 0;
    for (final entry in _dataChannels.entries) {
      final channel = entry.value;
      if (channel.state == RTCDataChannelState.RTCDataChannelOpen) {
        try {
          channel.send(RTCDataChannelMessage(message));
          successCount++;
          debugPrint('   ✅ Sent to ${entry.key}');
        } catch (e) {
          debugPrint('   ❌ Failed to send to ${entry.key}: $e');
        }
      } else {
        debugPrint('   ⏭️  Skip ${entry.key} - channel ${channel.state}');
      }
    }

    debugPrint('📊 Broadcast complete: $successCount/$openChannels successful');
  }

  void sendOperationToPeer(String peerId, Operation operation) {
    final channel = _dataChannels[peerId];
    if (channel == null) {
      debugPrint('⚠️  No channel for peer $peerId');
      return;
    }

    if (channel.state != RTCDataChannelState.RTCDataChannelOpen) {
      debugPrint('⚠️  Channel with $peerId not open - state: ${channel.state}');
      return;
    }

    try {
      final message = json.encode(operation.toJson());
      channel.send(RTCDataChannelMessage(message));
      debugPrint('📤 Sent operation ${operation.type.name} to $peerId');
    } catch (e) {
      debugPrint('❌ Error sending operation to $peerId: $e');
    }
  }

  void closePeerConnection(String peerId) {
    _dataChannels[peerId]?.close();
    _dataChannels.remove(peerId);

    _peerConnections[peerId]?.close();
    _peerConnections.remove(peerId);

    _pendingIceCandidates.remove(peerId);
    _makingOffer.remove(peerId);
    _ignoreOffer.remove(peerId);

    debugPrint('🔌 Closed connection with $peerId');
  }

  void closeAllConnections() {
    for (final peerId in _peerConnections.keys.toList()) {
      closePeerConnection(peerId);
    }
  }

  int get connectedPeersCount => _dataChannels.values
      .where((dc) => dc.state == RTCDataChannelState.RTCDataChannelOpen)
      .length;

  bool get isAudioEnabled => _isAudioEnabled;

  // ===== AUDIO STREAMING METHODS =====

  /// Start local audio stream and add to all peer connections
  Future<bool> startAudioStream() async {
    try {
      debugPrint('🎤 Starting audio stream...');

      // Get user media (audio only)
      _localAudioStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });

      debugPrint('✅ Local audio stream created');

      // Add audio tracks to all existing peer connections
      for (final entry in _peerConnections.entries) {
        final peerId = entry.key;
        final pc = entry.value;

        for (final track in _localAudioStream!.getAudioTracks()) {
          await pc.addTrack(track, _localAudioStream!);
          debugPrint('🎵 Added audio track to peer $peerId');
        }

        // Renegotiate connection to include audio
        await _renegotiateConnection(pc, peerId);
      }

      _isAudioEnabled = true;
      debugPrint('🎤 Audio streaming started successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to start audio stream: $e');
      return false;
    }
  }

  /// Stop local audio stream and remove from peer connections
  Future<void> stopAudioStream() async {
    try {
      debugPrint('🔇 Stopping audio stream...');

      if (_localAudioStream != null) {
        // Stop all audio tracks
        for (final track in _localAudioStream!.getAudioTracks()) {
          track.stop();
        }

        // Remove tracks from peer connections
        for (final entry in _peerConnections.entries) {
          final peerId = entry.key;
          final pc = entry.value;
          final senders = await pc.getSenders();

          for (final sender in senders) {
            if (sender.track?.kind == 'audio') {
              await pc.removeTrack(sender);
              debugPrint('🔇 Removed audio track from peer $peerId');
            }
          }

          // Renegotiate connection without audio
          await _renegotiateConnection(pc, peerId);
        }

        await _localAudioStream!.dispose();
        _localAudioStream = null;
      }

      // Clear remote audio streams
      for (final stream in _remoteAudioStreams.values) {
        await stream.dispose();
      }
      _remoteAudioStreams.clear();

      _isAudioEnabled = false;
      debugPrint('🔇 Audio streaming stopped');
    } catch (e) {
      debugPrint('❌ Failed to stop audio stream: $e');
    }
  }

  /// Renegotiate connection (create new offer/answer cycle)
  Future<void> _renegotiateConnection(
    RTCPeerConnection pc,
    String peerId,
  ) async {
    try {
      if (_makingOffer[peerId] == true) {
        debugPrint('⏳ Already making offer to $peerId, skipping renegotiation');
        return;
      }

      _makingOffer[peerId] = true;

      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      // Send offer through signaling (you'll need to implement this)
      // For now, just log it
      debugPrint('🔄 Created renegotiation offer for $peerId');

      _makingOffer[peerId] = false;
    } catch (e) {
      debugPrint('❌ Failed to renegotiate with $peerId: $e');
      _makingOffer[peerId] = false;
    }
  }

  /// Get remote audio stream for a specific peer
  MediaStream? getRemoteAudioStream(String peerId) {
    return _remoteAudioStreams[peerId];
  }

  /// Get all remote audio streams
  Map<String, MediaStream> get remoteAudioStreams =>
      Map.from(_remoteAudioStreams);
}
