import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Web-compatible P2P Service using BroadcastChannel API
/// This allows multiple tabs in same browser to communicate
class WebP2PService {
  final String boardId;
  final String peerId;
  
  // Callbacks
  final Function(String senderId, Map<String, dynamic> data)? onMessageReceived;
  final Function(String peerId)? onPeerJoined;
  final Function(String peerId)? onPeerLeft;
  
  // Internal
  html.BroadcastChannel? _channel;
  Timer? _heartbeatTimer;
  final Set<String> _connectedPeers = {};
  final Map<String, DateTime> _peerLastSeen = {};
  bool _isRunning = false;
  StreamSubscription? _messageSubscription;
  
  static const Duration _heartbeatInterval = Duration(seconds: 3);
  static const Duration _peerTimeout = Duration(seconds: 10);
  
  WebP2PService({
    required this.boardId,
    required this.peerId,
    this.onMessageReceived,
    this.onPeerJoined,
    this.onPeerLeft,
  });
  
  /// Start the P2P service
  Future<void> start() async {
    if (_isRunning) return;
    
    if (kIsWeb) {
      await _startWeb();
    } else {
      debugPrint('⚠️ WebP2PService only works on web platform');
    }
  }
  
  Future<void> _startWeb() async {
    try {
      debugPrint('🚀 Starting WebP2P for board: $boardId');
      
      // Create BroadcastChannel for this board
      _channel = html.BroadcastChannel('peer_task_board_$boardId');
      
      // Listen for messages from other tabs
      _messageSubscription = _channel!.onMessage.listen((event) {
        try {
          final data = event.data;
          if (data is String) {
            final message = jsonDecode(data) as Map<String, dynamic>;
            _handleMessage(message);
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing message: $e');
        }
      });
      
      _isRunning = true;
      
      // Start heartbeat
      _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
        _sendHeartbeat();
        _checkPeerTimeouts();
      });
      
      // Initial heartbeat
      _sendHeartbeat();
      
      debugPrint('✅ WebP2P started for $peerId on channel peer_task_board_$boardId');
    } catch (e) {
      debugPrint('❌ Error starting WebP2P: $e');
    }
  }
  
  void _sendHeartbeat() {
    if (!_isRunning) return;
    
    final message = {
      'type': 'heartbeat',
      'boardId': boardId,
      'peerId': peerId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    _broadcastMessage(message);
  }
  
  void _broadcastMessage(Map<String, dynamic> message) {
    if (!kIsWeb || _channel == null) return;
    
    try {
      final json = jsonEncode(message);
      _channel!.postMessage(json);
      debugPrint('📤 Broadcasting: ${message['type']} from $peerId');
    } catch (e) {
      debugPrint('⚠️ Error broadcasting: $e');
    }
  }
  
  void _handleMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    final senderId = message['peerId'] as String?;
    final messageBoardId = message['boardId'] as String?;
    
    // Ignore own messages and messages for other boards
    if (senderId == null || senderId == peerId) return;
    if (messageBoardId != boardId) return;
    
    debugPrint('📥 Received: $type from $senderId');
    
    // Update peer last seen
    _peerLastSeen[senderId] = DateTime.now();
    
    // Handle different message types
    switch (type) {
      case 'heartbeat':
        if (!_connectedPeers.contains(senderId)) {
          _connectedPeers.add(senderId);
          debugPrint('🎉 Peer joined: $senderId');
          onPeerJoined?.call(senderId);
        }
        break;
        
      case 'operation':
      case 'board_data':
        onMessageReceived?.call(senderId, message);
        break;
        
      case 'leave':
        _removePeer(senderId);
        break;
    }
  }
  
  void _checkPeerTimeouts() {
    final now = DateTime.now();
    final timedOut = <String>[];
    
    _peerLastSeen.forEach((peerId, lastSeen) {
      if (now.difference(lastSeen) > _peerTimeout) {
        timedOut.add(peerId);
      }
    });
    
    for (final peerId in timedOut) {
      _removePeer(peerId);
    }
  }
  
  void _removePeer(String peerId) {
    if (_connectedPeers.remove(peerId)) {
      _peerLastSeen.remove(peerId);
      debugPrint('👻 Peer left: $peerId');
      onPeerLeft?.call(peerId);
    }
  }
  
  /// Send data to all connected peers
  void broadcast(Map<String, dynamic> data) {
    if (!_isRunning) return;
    
    final message = {
      ...data,
      'boardId': boardId,
      'peerId': peerId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    _broadcastMessage(message);
  }
  
  /// Send board data to peers
  void sendBoardData(Map<String, dynamic> boardData) {
    broadcast({
      'type': 'board_data',
      'data': boardData,
    });
  }
  
  /// Send operation to peers
  void sendOperation(Map<String, dynamic> operation) {
    broadcast({
      'type': 'operation',
      'operation': operation,
    });
  }
  
  /// Stop the P2P service
  Future<void> stop() async {
    if (!_isRunning) return;
    
    // Send leave message
    broadcast({'type': 'leave'});
    
    _heartbeatTimer?.cancel();
    _messageSubscription?.cancel();
    _channel?.close();
    _channel = null;
    _isRunning = false;
    _connectedPeers.clear();
    _peerLastSeen.clear();
    
    debugPrint('🛑 WebP2P stopped');
  }
  
  /// Get list of connected peers
  List<String> get connectedPeers => _connectedPeers.toList();
  
  /// Check if running
  bool get isRunning => _isRunning;
  
  /// Get count of connected peers
  int get peerCount => _connectedPeers.length;
}
