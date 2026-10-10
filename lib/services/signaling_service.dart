import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/peer/peer.dart';

class SignalingService {
  final String serverUrl;
  final Function(List<Peer> peers)? onRoomJoined;
  final Function(Peer peer)? onPeerJoined;
  final Function(Peer peer)? onPeerLeft;
  final Function(String peerId, Map<String, dynamic> signal)? onSignal;
  final Function(String socketId, bool isMuted)? onPeerMicUpdated;
  final Function(String socketId, bool speaking)? onPeerSpeaking;
  final Function(Map<String, dynamic> operation)? onBoardOperation;
  final Function()? onDisconnected;
  final Function()? onReconnected;

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentBoardId;

  SignalingService({
    required this.serverUrl,
    this.onRoomJoined,
    this.onPeerJoined,
    this.onPeerLeft,
    this.onSignal,
    this.onPeerMicUpdated,
    this.onPeerSpeaking,
    this.onBoardOperation,
    this.onDisconnected,
    this.onReconnected,
  });

  bool get isConnected => _isConnected;

  void connect(String token) {
    debugPrint('🔌 Connecting to signaling server: $serverUrl');
    
    _socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['polling', 'websocket'],
      'upgrade': true,
      'autoConnect': false,
      'auth': {'token': token},
    });

    _socket!.onConnect((_) {
      debugPrint('✅ Connected to signaling server');
      _isConnected = true;
      if (_currentBoardId != null) {
        _socket!.emit('join_room', _currentBoardId);
      }
    });

    _socket!.on('room_joined', (data) {
      debugPrint('📥 Room joined event received');
      final raw = _asMap(data);
      final peers = <Peer>[];
      for (final item in (raw?['peers'] as List?) ?? const []) {
        final peer = _peerFrom(item);
        if (peer != null) peers.add(peer);
      }
      onRoomJoined?.call(peers);
    });

    _socket!.on('peer_joined', (data) {
      final peer = _peerFrom(data);
      if (peer == null) return;
      debugPrint('📥 Peer joined: ${peer.socketId}');
      onPeerJoined?.call(peer);
    });

    _socket!.on('peer_left', (data) {
      final peer = _peerFrom(data);
      if (peer == null) return;
      debugPrint('📤 Peer left: ${peer.socketId}');
      onPeerLeft?.call(peer);
    });

    _socket!.on('signal', (data) {
      final raw = _asMap(data);
      final peerId = raw?['from']?.toString();
      final signal = _asMap(raw?['signal']);
      if (peerId == null || signal == null) return;
      debugPrint('📡 Signal received from $peerId');
      onSignal?.call(peerId, signal);
    });

    _socket!.on('board_op', (data) {
      if (data is Map) {
        onBoardOperation?.call(Map<String, dynamic>.from(data));
      }
    });

    _socket!.on('peer_mic_updated', (data) {
      final socketId = data['socketId'] as String;
      final isMuted = data['isMuted'] as bool;
      debugPrint('🎤 Peer mic updated: $socketId -> ${isMuted ? "muted" : "unmuted"}');
      onPeerMicUpdated?.call(socketId, isMuted);
    });

    _socket!.on('peer_speaking', (data) {
      final socketId = data['socketId'] as String;
      final speaking = data['speaking'] == true;
      onPeerSpeaking?.call(socketId, speaking);
    });

    _socket!.onDisconnect((_) {
      debugPrint('❌ Disconnected from signaling server');
      _isConnected = false;
      onDisconnected?.call();
    });

    _socket!.onReconnect((_) {
      debugPrint('♻️ Reconnected to signaling server');
      _isConnected = true;
      onReconnected?.call();
    });

    _socket!.onError((error) {
      debugPrint('❌ Socket error: $error');
    });

    _socket!.on('connect_error', (error) {
      debugPrint('❌ Signaling connect_error: $error');
    });

    _socket!.connect();
  }

  void joinRoom(String boardId) {
    _currentBoardId = boardId;
    if (_isConnected) {
      debugPrint('🚪 Joining room: $boardId');
      _socket?.emit('join_room', boardId);
    }
  }

  void sendSignal(String targetPeerId, Map<String, dynamic> signal) {
    if (!_isConnected) {
      debugPrint('⚠️ Cannot send signal: not connected');
      return;
    }
    _socket?.emit('signal', {
      'to': targetPeerId,
      'signal': signal,
    });
  }

  void sendBoardOperation(Map<String, dynamic> operation) {
    if (!_isConnected) return;
    _socket?.emit('board_op', operation);
  }

  void updateMicStatus(bool isMuted) {
    if (!_isConnected) return;
    _socket?.emit('update_mic_status', {'isMuted': isMuted});
  }

  void updateSpeaking(bool speaking) {
    if (!_isConnected) return;
    _socket?.emit('speaking', {'speaking': speaking});
  }

  void disconnect() {
    debugPrint('🔌 Disconnecting from signaling server');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _currentBoardId = null;
  }
}

Map<String, dynamic>? _asMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return null;
}

Peer? _peerFrom(dynamic data) {
  final json = _asMap(data);
  if (json == null) return null;
  final socketId = json['socketId']?.toString();
  final userId = json['userId']?.toString();
  if (socketId == null || socketId.isEmpty || userId == null || userId.isEmpty) {
    return null;
  }
  json['socketId'] = socketId;
  json['userId'] = userId;
  try {
    return Peer.fromJson(json);
  } catch (e) {
    debugPrint('Peer payload skipped: $e');
    return null;
  }
}
