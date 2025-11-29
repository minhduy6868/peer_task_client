import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/peer/peer.dart';

class SignalingService {
  final String serverUrl;
  io.Socket? _socket;
  String? _currentRoom;
  String? _pendingRoom; // Room to join after connection
  // ignore: unused_field
  String? _currentToken; // Stored for potential future reconnection logic
  bool _isReconnecting = false;

  final Function(List<Peer>)? onRoomJoined;
  final Function(Peer)? onPeerJoined;
  final Function(Peer)? onPeerLeft;
  final Function(String from, Map<String, dynamic> signal)? onSignal;
  final Function()? onReconnected;

  SignalingService({
    required this.serverUrl,
    this.onRoomJoined,
    this.onPeerJoined,
    this.onPeerLeft,
    this.onSignal,
    this.onReconnected,
  });

  void connect(String token) {
    _currentToken = token;
    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('✅ Connected to signaling server (socketId: ${_socket!.id})');
      
      // Join pending room if any
      if (_pendingRoom != null && !_isReconnecting) {
        final room = _pendingRoom!;
        _pendingRoom = null;
        debugPrint('🚪 Auto-joining pending room: $room');
        joinRoom(room);
      }
      
      // If we were reconnecting and had a room, rejoin it
      if (_isReconnecting && _currentRoom != null) {
        _isReconnecting = false;
        debugPrint('♻️ Rejoining room after reconnection: $_currentRoom');
        _socket!.emit('join_room', _currentRoom);
        onReconnected?.call();
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('❌ Disconnected from signaling server');
      if (_currentRoom != null) {
        _isReconnecting = true;
      }
    });

    _socket!.on('room_joined', (data) {
      debugPrint('📥 Room joined: $data');
      final peers = (data['peers'] as List)
          .map((p) => Peer.fromJson(p as Map<String, dynamic>))
          .toList();
      onRoomJoined?.call(peers);
    });

    _socket!.on('peer_joined', (data) {
      debugPrint('📥 Peer joined: $data');
      final peer = Peer.fromJson(data as Map<String, dynamic>);
      onPeerJoined?.call(peer);
    });

    _socket!.on('peer_left', (data) {
      debugPrint('📥 Peer left: $data');
      final peer = Peer.fromJson(data as Map<String, dynamic>);
      onPeerLeft?.call(peer);
    });

    _socket!.on('signal', (data) {
      debugPrint('📥 Signal from ${data['from']}');
      onSignal?.call(data['from'] as String, data['signal'] as Map<String, dynamic>);
    });

    _socket!.on('error', (error) {
      debugPrint('❌ Signaling error: $error');
    });
  }

  void joinRoom(String roomId) {
    if (_socket == null) {
      debugPrint('❌ Cannot join room: socket is null');
      throw Exception('Socket not initialized');
    }
    
    if (!_socket!.connected) {
      debugPrint('⏳ Socket not connected yet, queuing room join: $roomId');
      _pendingRoom = roomId;
      return;
    }

    _currentRoom = roomId;
    debugPrint('📤 Joining room: $roomId (socketId: ${_socket!.id})');
    _socket!.emit('join_room', roomId);
  }

  void leaveRoom() {
    if (_socket != null && _currentRoom != null) {
      _socket!.emit('leave_room');
      _currentRoom = null;
      debugPrint('📤 Left room');
    }
  }

  void sendSignal(String to, Map<String, dynamic> signal) {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Not connected to signaling server');
    }

    _socket!.emit('signal', {
      'to': to,
      'signal': signal,
    });
    debugPrint('📤 Sent signal to $to');
  }

  void disconnect() {
    leaveRoom();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  bool get isConnected => _socket?.connected ?? false;
}
