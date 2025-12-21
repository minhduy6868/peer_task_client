import 'package:flutter/foundation.dart';
import '../models/operation/operation.dart';

/// Stub implementation of NativeP2PService for web platform
/// This allows the code to compile on web even though native P2P is not available
class NativeP2PService {
  final String boardId;
  final String userId;
  final String deviceName;

  // Callbacks
  Function(String peerId, String? deviceName)? onPeerJoined;
  Function(String peerId)? onPeerLeft;
  Function(Operation operation)? onOperationReceived;
  Function(Map<String, dynamic> boardData)? onBoardDataReceived;

  NativeP2PService({
    required this.boardId,
    required this.userId,
    required this.deviceName,
  });

  Future<void> start() async {
    debugPrint('⚠️ NativeP2PService not available on web');
  }

  Future<void> stop() async {
    debugPrint('⚠️ NativeP2PService not available on web');
  }

  void broadcastOperation(Operation operation) {
    debugPrint('⚠️ NativeP2PService not available on web');
  }

  void sendBoardData(String peerId, Map<String, dynamic> data) {
    debugPrint('⚠️ NativeP2PService not available on web');
  }

  String get localIp => 'N/A';
  int get connectedPeerCount => 0;
  List<String> get connectedPeers => [];
}
