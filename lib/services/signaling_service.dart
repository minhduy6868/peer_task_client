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
    this.onDisconnected,
    this.onReconnected,
  });

  bool get isConnected => _isConnected;

  void connect(String token) {
    debugPrint('🔌 Connecting to signaling server: $serverUrl');
    
    _socket = IO.io(serverUrl, <String, dynamic>{
      'transports': ['websocket'],
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
      final peers = (data['peers'] as List?)
          ?.map((p) => Peer.fromJson(p as Map<String, dynamic>))
          .toList() ?? [];
      onRoomJoined?.call(peers);
    });

    _socket!.on('peer_joined', (data) {
      debugPrint('📥 Peer joined: ${data['socketId']}');
      onPeerJoined?.call(Peer.fromJson(data as Map<String, dynamic>));
    });

    _socket!.on('peer_left', (data) {
      debugPrint('📤 Peer left: ${data['socketId']}');
      onPeerLeft?.call(Peer.fromJson(data as Map<String, dynamic>));
    });

    _socket!.on('signal', (data) {
      final peerId = data['from'] as String;
      final signal = data['signal'] as Map<String, dynamic>;
      debugPrint('📡 Signal received from $peerId');
      onSignal?.call(peerId, signal);
    });

    _socket!.on('peer_mic_updated', (data) {
      final socketId = data['socketId'] as String;
      final isMuted = data['isMuted'] as bool;
      debugPrint('🎤 Peer mic updated: $socketId -> ${isMuted ? "muted" : "unmuted"}');
      onPeerMicUpdated?.call(socketId, isMuted);
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

  void updateMicStatus(bool isMuted) {
    if (!_isConnected) return;
    _socket?.emit('update_mic_status', {'isMuted': isMuted});
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
