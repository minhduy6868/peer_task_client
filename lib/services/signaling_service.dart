import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/peer.dart';

class SignalingService {
  final String serverUrl;
  io.Socket? _socket;
  String? _currentRoom;

  final Function(List<Peer>)? onRoomJoined;
  final Function(Peer)? onPeerJoined;
  final Function(Peer)? onPeerLeft;
  final Function(String from, Map<String, dynamic> signal)? onSignal;

  SignalingService({
    required this.serverUrl,
    this.onRoomJoined,
    this.onPeerJoined,
    this.onPeerLeft,
    this.onSignal,
  });

  void connect(String token) {
    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      print('✅ Connected to signaling server');
    });

    _socket!.onDisconnect((_) {
      print('❌ Disconnected from signaling server');
    });

    _socket!.on('room_joined', (data) {
      print('📥 Room joined: $data');
      final peers = (data['peers'] as List)
          .map((p) => Peer.fromJson(p as Map<String, dynamic>))
          .toList();
      onRoomJoined?.call(peers);
    });

    _socket!.on('peer_joined', (data) {
      print('📥 Peer joined: $data');
      final peer = Peer.fromJson(data as Map<String, dynamic>);
      onPeerJoined?.call(peer);
    });

    _socket!.on('peer_left', (data) {
      print('📥 Peer left: $data');
      final peer = Peer.fromJson(data as Map<String, dynamic>);
      onPeerLeft?.call(peer);
    });

    _socket!.on('signal', (data) {
      print('📥 Signal from ${data['from']}');
      onSignal?.call(data['from'] as String, data['signal'] as Map<String, dynamic>);
    });

    _socket!.on('error', (error) {
      print('❌ Signaling error: $error');
    });
  }

  void joinRoom(String roomId) {
    if (_socket == null || !_socket!.connected) {
      throw Exception('Not connected to signaling server');
    }

    _currentRoom = roomId;
    _socket!.emit('join_room', roomId);
    print('📤 Joining room: $roomId');
  }

  void leaveRoom() {
    if (_socket != null && _currentRoom != null) {
      _socket!.emit('leave_room');
      _currentRoom = null;
      print('📤 Left room');
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
    print('📤 Sent signal to $to');
  }

  void disconnect() {
    leaveRoom();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  bool get isConnected => _socket?.connected ?? false;
}
