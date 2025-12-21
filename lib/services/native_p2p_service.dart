import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/operation/operation.dart';

/// Native P2P Service for Desktop/Mobile
/// Uses UDP broadcast for peer discovery and TCP for data sync
class NativeP2PService {
  final String boardId;
  final String _userId;
  final String deviceName;
  
  // Callbacks
  Function(String peerId, String deviceName)? onPeerJoined;
  Function(String peerId)? onPeerLeft;
  Function(Operation operation)? onOperationReceived;
  Function(Map<String, dynamic> boardData)? onBoardDataReceived;

  // UDP for discovery
  RawDatagramSocket? _udpSocket;
  
  // TCP for data transfer
  ServerSocket? _tcpServer;
  final Map<String, Socket> _tcpConnections = {};
  
  // State
  final Map<String, _PeerInfo> _peers = {};
  Timer? _heartbeatTimer;
  Timer? _cleanupTimer;
  bool _isRunning = false;
  String? _localIp;
  
  // Ports
  static const int _udpPort = 41234;
  static const int _tcpPort = 41235;

  NativeP2PService({
    required this.boardId,
    required String userId,
    required this.deviceName,
  }) : _userId = userId;

  String get userId => _userId;

  /// Start P2P service
  Future<void> start() async {
    if (_isRunning) return;
    
    debugPrint('🚀 Starting Native P2P Service...');
    debugPrint('   Board: $boardId');
    debugPrint('   User: $userId');
    debugPrint('   Device: $deviceName');

    try {
      // Get local IP
      _localIp = await _getLocalIp();
      debugPrint('📍 Local IP: $_localIp');

      // Start UDP socket for discovery
      await _startUdpDiscovery();
      
      // Start TCP server for data transfer
      await _startTcpServer();

      _isRunning = true;

      // Start heartbeat
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _broadcastPresence();
      });

      // Start cleanup timer
      _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _cleanupStalePeers();
      });

      debugPrint('✅ Native P2P Service started');
    } catch (e) {
      debugPrint('❌ Error starting P2P: $e');
      rethrow;
    }
  }

  /// Stop P2P service
  Future<void> stop() async {
    if (!_isRunning) return;

    debugPrint('🛑 Stopping Native P2P Service...');

    _heartbeatTimer?.cancel();
    _cleanupTimer?.cancel();
    
    // Close TCP connections
    for (final socket in _tcpConnections.values) {
      await socket.close();
    }
    _tcpConnections.clear();
    
    await _tcpServer?.close();
    _udpSocket?.close();
    _peers.clear();
    
    _isRunning = false;
    debugPrint('✅ Native P2P Service stopped');
  }

  /// Start UDP discovery
  Future<void> _startUdpDiscovery() async {
    _udpSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      _udpPort,
      reuseAddress: true,
    );
    _udpSocket!.broadcastEnabled = true;

    debugPrint('📡 UDP listening on port $_udpPort');

    _udpSocket!.listen((event) {
      if (event == RawSocketEvent.read) {
        _handleUdpMessage();
      }
    });
  }

  /// Start TCP server for data transfer
  Future<void> _startTcpServer() async {
    _tcpServer = await ServerSocket.bind(
      InternetAddress.anyIPv4,
      _tcpPort,
    );

    debugPrint('🔌 TCP server listening on port $_tcpPort');

    _tcpServer!.listen((socket) {
      _handleTcpConnection(socket);
    });
  }

  /// Broadcast presence to LAN
  void _broadcastPresence() {
    if (_udpSocket == null) return;

    final message = jsonEncode({
      'type': 'presence',
      'boardId': boardId,
      'userId': userId,
      'deviceName': deviceName,
      'ip': _localIp,
      'tcpPort': _tcpPort,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    try {
      _udpSocket!.send(
        utf8.encode(message),
        InternetAddress('255.255.255.255'),
        _udpPort,
      );
    } catch (e) {
      debugPrint('⚠️ Error broadcasting: $e');
    }
  }

  /// Handle incoming UDP message
  void _handleUdpMessage() {
    final datagram = _udpSocket?.receive();
    if (datagram == null) return;

    try {
      final message = jsonDecode(utf8.decode(datagram.data));
      final type = message['type'] as String?;
      final peerId = message['userId'] as String?;
      final peerBoardId = message['boardId'] as String?;

      // Ignore self
      if (peerId == userId) return;

      // Check if board codes match (first 8 chars of boardId)
      final myCode = boardId.substring(0, 8).toLowerCase();
      final peerCode = peerBoardId?.substring(0, 8).toLowerCase();
      
      if (peerCode != myCode) return; // Different board codes

      if (type == 'presence') {
        _handlePeerPresence(message, datagram.address.address);
      }
    } catch (e) {
      // Ignore parse errors
    }
  }

  /// Handle peer presence message
  void _handlePeerPresence(Map<String, dynamic> message, String sourceIp) {
    final peerId = message['userId'] as String;
    final deviceName = message['deviceName'] as String? ?? 'Unknown';
    final tcpPort = message['tcpPort'] as int? ?? _tcpPort;
    final peerIp = message['ip'] as String? ?? sourceIp;
    final peerBoardId = message['boardId'] as String?;

    debugPrint('📡 Presence from: $deviceName ($peerIp)');
    debugPrint('   Peer boardId: $peerBoardId');
    debugPrint('   My boardId: $boardId');

    final isNew = !_peers.containsKey(peerId);
    
    _peers[peerId] = _PeerInfo(
      userId: peerId,
      deviceName: deviceName,
      ip: peerIp,
      tcpPort: tcpPort,
      lastSeen: DateTime.now(),
    );

    if (isNew) {
      debugPrint('🎉 New peer discovered: $deviceName ($peerIp)');
      onPeerJoined?.call(peerId, deviceName);
      
      // Connect to peer's TCP server
      _connectToPeer(peerId);
    } else {
      debugPrint('♻️ Peer heartbeat: $deviceName');
    }
  }

  /// Connect to peer's TCP server
  Future<void> _connectToPeer(String peerId) async {
    final peer = _peers[peerId];
    if (peer == null) return;

    if (_tcpConnections.containsKey(peerId)) return;

    try {
      debugPrint('🔗 Connecting to peer $peerId at ${peer.ip}:${peer.tcpPort}...');
      
      final socket = await Socket.connect(
        peer.ip,
        peer.tcpPort,
        timeout: const Duration(seconds: 5),
      );

      _tcpConnections[peerId] = socket;
      debugPrint('✅ Connected to peer $peerId');

      // Listen for data from peer
      socket.listen(
        (data) => _handleTcpData(peerId, data),
        onError: (e) {
          debugPrint('❌ TCP error with $peerId: $e');
          _disconnectPeer(peerId);
        },
        onDone: () {
          debugPrint('📴 TCP connection closed with $peerId');
          _disconnectPeer(peerId);
        },
      );

      // Send handshake
      _sendToPeer(peerId, {
        'type': 'handshake',
        'userId': userId,
        'deviceName': deviceName,
      });
    } catch (e) {
      debugPrint('❌ Failed to connect to peer $peerId: $e');
    }
  }

  /// Handle incoming TCP connection
  void _handleTcpConnection(Socket socket) {
    debugPrint('📥 Incoming TCP connection from ${socket.remoteAddress.address}');

    String? connectedPeerId;

    socket.listen(
      (data) {
        try {
          final message = jsonDecode(utf8.decode(data));
          final type = message['type'] as String?;

          if (type == 'handshake') {
            connectedPeerId = message['userId'] as String?;
            if (connectedPeerId != null && !_tcpConnections.containsKey(connectedPeerId)) {
              _tcpConnections[connectedPeerId!] = socket;
              debugPrint('✅ Handshake complete with $connectedPeerId');
            }
          } else if (connectedPeerId != null) {
            // Handle other message types directly without re-parsing
            _handleTcpMessage(connectedPeerId!, message);
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing TCP data: $e');
        }
      },
      onError: (e) {
        debugPrint('❌ TCP error: $e');
        if (connectedPeerId != null) {
          _disconnectPeer(connectedPeerId!);
        }
      },
      onDone: () {
        if (connectedPeerId != null) {
          _disconnectPeer(connectedPeerId!);
        }
      },
    );
  }

  /// Handle TCP data from peer
  void _handleTcpData(String peerId, List<int> data) {
    try {
      final message = jsonDecode(utf8.decode(data));
      _handleTcpMessage(peerId, message);
    } catch (e) {
      debugPrint('⚠️ Error handling TCP data: $e');
    }
  }

  /// Handle parsed TCP message
  void _handleTcpMessage(String peerId, Map<String, dynamic> message) {
    try {
      final type = message['type'] as String?;

      switch (type) {
        case 'operation':
          final opData = message['operation'] as Map<String, dynamic>;
          final operation = Operation.fromJson(opData);
          debugPrint('📥 Received operation from $peerId: ${operation.type}');
          onOperationReceived?.call(operation);
          break;
          
        case 'board_data':
          final boardData = message['data'] as Map<String, dynamic>;
          debugPrint('📥 Received board data from $peerId');
          onBoardDataReceived?.call(boardData);
          break;
          
        case 'handshake':
          // Already handled in _handleTcpConnection
          debugPrint('🤝 Handshake message from $peerId');
          break;
      }
    } catch (e) {
      debugPrint('⚠️ Error handling message: $e');
    }
  }

  /// Send operation to all peers
  void broadcastOperation(Operation operation) {
    final message = {
      'type': 'operation',
      'operation': operation.toJson(),
    };

    for (final peerId in _tcpConnections.keys) {
      _sendToPeer(peerId, message);
    }
    
    debugPrint('📤 Broadcast operation to ${_tcpConnections.length} peers');
  }

  /// Send board data to specific peer
  void sendBoardData(String peerId, Map<String, dynamic> data) {
    _sendToPeer(peerId, {
      'type': 'board_data',
      'data': data,
    });
  }

  /// Send message to specific peer
  void _sendToPeer(String peerId, Map<String, dynamic> message) {
    final socket = _tcpConnections[peerId];
    if (socket == null) return;

    try {
      socket.add(utf8.encode(jsonEncode(message)));
    } catch (e) {
      debugPrint('⚠️ Error sending to $peerId: $e');
    }
  }

  /// Disconnect peer
  void _disconnectPeer(String peerId) {
    _tcpConnections[peerId]?.close();
    _tcpConnections.remove(peerId);
    _peers.remove(peerId);
    onPeerLeft?.call(peerId);
  }

  /// Cleanup stale peers
  void _cleanupStalePeers() {
    final now = DateTime.now();
    final staleIds = <String>[];

    for (final entry in _peers.entries) {
      if (now.difference(entry.value.lastSeen).inSeconds > 10) {
        staleIds.add(entry.key);
      }
    }

    for (final id in staleIds) {
      debugPrint('👻 Peer timeout: $id');
      _disconnectPeer(id);
    }
  }

  /// Get local IP address
  Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        if (interface.name.contains('lo')) continue;
        
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && 
              !addr.address.startsWith('127.')) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error getting local IP: $e');
    }
    return null;
  }

  /// Get connected peer count
  int get connectedPeerCount => _tcpConnections.length;

  /// Get list of connected peers
  List<String> get connectedPeers => _tcpConnections.keys.toList();

  /// Check if running
  bool get isRunning => _isRunning;
}

class _PeerInfo {
  final String _userId;
  final String deviceName;
  final String ip;
  final int tcpPort;
  DateTime lastSeen;

  _PeerInfo({
    required String userId,
    required this.deviceName,
    required this.ip,
    required this.tcpPort,
    required this.lastSeen,
  }) : _userId = userId;

  String get userId => _userId;
}
