import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/operation.dart';

class WebRTCService {
  final String userId;
  final Function(String peerId, Operation operation)? onOperationReceived;
  final Function(String peerId)? onPeerConnected;
  final Function(String peerId)? onPeerDisconnected;

  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, RTCDataChannel> _dataChannels = {};

  WebRTCService({
    required this.userId,
    this.onOperationReceived,
    this.onPeerConnected,
    this.onPeerDisconnected,
  });

  Future<void> initPeerConnection(
    String peerId,
    Function(Map<String, dynamic>) onLocalDescription,
  ) async {
    print('🔗 Creating peer connection for $peerId');

    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    final pc = await createPeerConnection(configuration);
    _peerConnections[peerId] = pc;

    // Create data channel
    final dc = await pc.createDataChannel('board_ops', RTCDataChannelInit());
    _dataChannels[peerId] = dc;

    _setupDataChannel(dc, peerId);

    // Create offer
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    pc.onIceCandidate = (candidate) {
      onLocalDescription({
        'type': 'ice',
        'candidate': candidate.toMap(),
      });
    };

    onLocalDescription({
      'type': 'offer',
      'sdp': offer.sdp,
    });
  }

  Future<void> handleSignal(
    String peerId,
    Map<String, dynamic> signal,
    Function(Map<String, dynamic>)? onLocalDescription,
  ) async {
    print('📡 Handling signal from $peerId: ${signal['type']}');

    if (signal['type'] == 'offer') {
      await _handleOffer(peerId, signal, onLocalDescription!);
    } else if (signal['type'] == 'answer') {
      await _handleAnswer(peerId, signal);
    } else if (signal['type'] == 'ice') {
      await _handleIceCandidate(peerId, signal);
    }
  }

  Future<void> _handleOffer(
    String peerId,
    Map<String, dynamic> signal,
    Function(Map<String, dynamic>) onLocalDescription,
  ) async {
    print('📥 Handling offer from $peerId');

    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    final pc = await createPeerConnection(configuration);
    _peerConnections[peerId] = pc;

    pc.onDataChannel = (channel) {
      print('📥 Data channel received from $peerId');
      _dataChannels[peerId] = channel;
      _setupDataChannel(channel, peerId);
    };

    pc.onIceCandidate = (candidate) {
      onLocalDescription({
        'type': 'ice',
        'candidate': candidate.toMap(),
      });
    };

    await pc.setRemoteDescription(
      RTCSessionDescription(signal['sdp'], signal['type']),
    );

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    onLocalDescription({
      'type': 'answer',
      'sdp': answer.sdp,
    });
  }

  Future<void> _handleAnswer(String peerId, Map<String, dynamic> signal) async {
    final pc = _peerConnections[peerId];
    if (pc != null) {
      await pc.setRemoteDescription(
        RTCSessionDescription(signal['sdp'], signal['type']),
      );
    }
  }

  Future<void> _handleIceCandidate(
    String peerId,
    Map<String, dynamic> signal,
  ) async {
    final pc = _peerConnections[peerId];
    if (pc != null && signal['candidate'] != null) {
      await pc.addCandidate(RTCIceCandidate(
        signal['candidate']['candidate'],
        signal['candidate']['sdpMid'],
        signal['candidate']['sdpMLineIndex'],
      ));
    }
  }

  void _setupDataChannel(RTCDataChannel channel, String peerId) {
    channel.onMessage = (message) {
      print('📨 Message from $peerId: ${message.text.substring(0, 50)}...');
      try {
        final data = json.decode(message.text);
        final operation = Operation.fromJson(data);
        onOperationReceived?.call(peerId, operation);
      } catch (e) {
        print('❌ Error parsing operation: $e');
      }
    };

    channel.onDataChannelState = (state) {
      print('🔄 Data channel state with $peerId: $state');
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        onPeerConnected?.call(peerId);
      } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
        onPeerDisconnected?.call(peerId);
      }
    };
  }

  void sendOperation(Operation operation) {
    final message = json.encode(operation.toJson());
    print('📤 Broadcasting operation to ${_dataChannels.length} peers');

    for (final entry in _dataChannels.entries) {
      final channel = entry.value;
      if (channel.state == RTCDataChannelState.RTCDataChannelOpen) {
        channel.send(RTCDataChannelMessage(message));
      }
    }
  }

  void closePeerConnection(String peerId) {
    _dataChannels[peerId]?.close();
    _dataChannels.remove(peerId);

    _peerConnections[peerId]?.close();
    _peerConnections.remove(peerId);

    print('🔌 Closed connection with $peerId');
  }

  void closeAllConnections() {
    for (final peerId in _peerConnections.keys.toList()) {
      closePeerConnection(peerId);
    }
  }

  int get connectedPeersCount => _dataChannels.values
      .where((dc) => dc.state == RTCDataChannelState.RTCDataChannelOpen)
      .length;
}
