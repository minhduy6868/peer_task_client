import 'package:flutter/foundation.dart';
import '../../utils/platform_utils.dart';
import '../../models/operation/operation.dart';
import 'p2p_service_interface.dart';
import '../native_p2p_service.dart'
    if (dart.library.html) '../native_p2p_service_stub.dart';
import '../web_p2p_service.dart';

/// Unified P2P Manager that handles both Web and Native P2P
/// This is the main entry point for P2P functionality
class P2PManager implements P2PServiceInterface {
  final String boardId;
  final String userId;
  final String deviceName;

  // Internal services
  NativeP2PService? _nativeService;
  WebP2PService? _webService;

  // Callbacks
  Function(String peerId, String? deviceName)? _onPeerJoined;
  Function(String peerId)? _onPeerLeft;
  Function(Operation operation)? _onOperationReceived;
  Function(Map<String, dynamic> boardData)? _onBoardDataReceived;

  // State
  bool _isRunning = false;

  P2PManager({
    required this.boardId,
    required this.userId,
    required this.deviceName,
  });

  /// Factory constructor for easier creation
  factory P2PManager.create({
    required String boardId,
    required String userId,
    String? deviceName,
  }) {
    final name = deviceName ?? '$userId (${PlatformUtils.platformName})';
    return P2PManager(
      boardId: boardId,
      userId: userId,
      deviceName: name,
    );
  }

  @override
  Future<void> start() async {
    if (_isRunning) return;

    debugPrint('🚀 P2PManager starting...');
    debugPrint('   Platform: ${PlatformUtils.platformName}');
    debugPrint('   P2P LAN Supported: ${PlatformUtils.isP2PLanSupported}');

    try {
      if (PlatformUtils.isP2PLanSupported) {
        // Native platform - use UDP/TCP for true LAN P2P
        await _startNativeP2P();
      } else if (kIsWeb) {
        // Web platform - use BroadcastChannel (same browser only)
        await _startWebP2P();
      } else {
        debugPrint('⚠️ P2P not supported on this platform');
        return;
      }

      _isRunning = true;
      debugPrint('✅ P2PManager started');
    } catch (e) {
      debugPrint('❌ P2PManager failed to start: $e');
      rethrow;
    }
  }

  Future<void> _startNativeP2P() async {
    _nativeService = NativeP2PService(
      boardId: boardId,
      userId: userId,
      deviceName: deviceName,
    );

    _nativeService!.onPeerJoined = (peerId, peerDeviceName) {
      debugPrint('🎉 Native P2P: Peer joined: $peerDeviceName');
      _onPeerJoined?.call(peerId, peerDeviceName);
    };

    _nativeService!.onPeerLeft = (peerId) {
      debugPrint('👋 Native P2P: Peer left: $peerId');
      _onPeerLeft?.call(peerId);
    };

    _nativeService!.onOperationReceived = (operation) {
      debugPrint('📥 Native P2P: Operation received: ${operation.type}');
      _onOperationReceived?.call(operation);
    };

    _nativeService!.onBoardDataReceived = (data) {
      debugPrint('📥 Native P2P: Board data received');
      _onBoardDataReceived?.call(data);
    };

    await _nativeService!.start();
  }

  Future<void> _startWebP2P() async {
    _webService = WebP2PService(
      boardId: boardId,
      peerId: userId,
      onPeerJoined: (peerId) {
        debugPrint('🎉 Web P2P: Peer joined: $peerId');
        _onPeerJoined?.call(peerId, null);
      },
      onPeerLeft: (peerId) {
        debugPrint('👋 Web P2P: Peer left: $peerId');
        _onPeerLeft?.call(peerId);
      },
      onMessageReceived: (senderId, data) {
        _handleWebMessage(senderId, data);
      },
    );

    await _webService!.start();
  }

  void _handleWebMessage(String senderId, Map<String, dynamic> data) {
    final type = data['type'] as String?;

    switch (type) {
      case 'operation':
        final opData = data['operation'] as Map<String, dynamic>?;
        if (opData != null) {
          try {
            // Try to parse as Operation from opData
            final opType = opData['type'] as String?;
            final payload = opData['data'] as Map<String, dynamic>?;
            if (opType != null && payload != null) {
              final operation = Operation(
                opId: 'remote-${DateTime.now().millisecondsSinceEpoch}',
                actor: senderId,
                timestamp: DateTime.now().millisecondsSinceEpoch,
                type: _parseOperationType(opType),
                payload: {'id': payload['id'], 'type': payload['type'], 'data': payload},
              );
              _onOperationReceived?.call(operation);
            }
          } catch (e) {
            debugPrint('⚠️ Error parsing web operation: $e');
          }
        }
        break;

      case 'board_data':
        final boardData = data['data'] as Map<String, dynamic>?;
        if (boardData != null) {
          _onBoardDataReceived?.call(boardData);
        }
        break;
    }
  }

  OperationType _parseOperationType(String type) {
    if (type.contains('createObject') || type.contains('create')) {
      return OperationType.createObject;
    } else if (type.contains('updateObject') || type.contains('update')) {
      return OperationType.updateObject;
    } else if (type.contains('deleteObject') || type.contains('delete')) {
      return OperationType.deleteObject;
    }
    return OperationType.updateObject;
  }

  @override
  Future<void> stop() async {
    if (!_isRunning) return;

    debugPrint('🛑 P2PManager stopping...');

    await _nativeService?.stop();
    await _webService?.stop();

    _nativeService = null;
    _webService = null;
    _isRunning = false;

    debugPrint('✅ P2PManager stopped');
  }

  @override
  void broadcastOperation(Operation operation) {
    if (!_isRunning) return;

    if (_nativeService != null) {
      _nativeService!.broadcastOperation(operation);
    }

    if (_webService != null) {
      _webService!.sendOperation({
        'type': operation.type.toString(),
        'data': operation.payload,
      });
    }
  }

  @override
  void sendBoardData(Map<String, dynamic> data) {
    if (!_isRunning) return;

    // Native: send to all peers
    if (_nativeService != null) {
      for (final peerId in _nativeService!.connectedPeers) {
        _nativeService!.sendBoardData(peerId, data);
      }
    }

    // Web: broadcast
    if (_webService != null) {
      _webService!.sendBoardData(data);
    }
  }

  @override
  bool get isRunning => _isRunning;

  @override
  int get connectedPeerCount {
    if (_nativeService != null) {
      return _nativeService!.connectedPeerCount;
    }
    if (_webService != null) {
      return _webService!.peerCount;
    }
    return 0;
  }

  @override
  List<String> get connectedPeers {
    if (_nativeService != null) {
      return _nativeService!.connectedPeers;
    }
    if (_webService != null) {
      return _webService!.connectedPeers;
    }
    return [];
  }

  @override
  set onPeerJoined(Function(String peerId, String? deviceName)? callback) {
    _onPeerJoined = callback;
  }

  @override
  set onPeerLeft(Function(String peerId)? callback) {
    _onPeerLeft = callback;
  }

  @override
  set onOperationReceived(Function(Operation operation)? callback) {
    _onOperationReceived = callback;
  }

  @override
  set onBoardDataReceived(Function(Map<String, dynamic> boardData)? callback) {
    _onBoardDataReceived = callback;
  }

  /// Get platform-specific P2P status message
  String get statusMessage {
    if (!_isRunning) {
      return 'P2P not started';
    }

    if (PlatformUtils.isP2PLanSupported) {
      final count = connectedPeerCount;
      if (count > 0) {
        return '$count peer(s) connected via LAN';
      }
      return 'Searching for peers on LAN...';
    } else if (kIsWeb) {
      final count = connectedPeerCount;
      if (count > 0) {
        return '$count peer(s) connected (same browser)';
      }
      return 'Listening (same browser tabs only)';
    }

    return 'P2P not supported';
  }
}
