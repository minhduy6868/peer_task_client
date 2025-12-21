import '../../models/operation/operation.dart';

/// Base interface for all P2P services
/// This provides a unified API for both Web and Native P2P implementations
abstract class P2PServiceInterface {
  /// Start the P2P service
  Future<void> start();

  /// Stop the P2P service
  Future<void> stop();

  /// Broadcast an operation to all connected peers
  void broadcastOperation(Operation operation);

  /// Send board data to all peers (for initial sync)
  void sendBoardData(Map<String, dynamic> data);

  /// Check if the service is running
  bool get isRunning;

  /// Get the number of connected peers
  int get connectedPeerCount;

  /// Get list of connected peer IDs
  List<String> get connectedPeers;

  /// Callback when a peer joins
  set onPeerJoined(Function(String peerId, String? deviceName)? callback);

  /// Callback when a peer leaves
  set onPeerLeft(Function(String peerId)? callback);

  /// Callback when an operation is received from a peer
  set onOperationReceived(Function(Operation operation)? callback);

  /// Callback when board data is received (for sync)
  set onBoardDataReceived(Function(Map<String, dynamic> boardData)? callback);
}

/// P2P Connection status for UI display
enum P2PConnectionStatus {
  disconnected,
  connecting,
  connected,
}

/// P2P Peer info
class P2PPeer {
  final String id;
  final String deviceName;
  final DateTime lastSeen;
  final bool isConnected;

  P2PPeer({
    required this.id,
    required this.deviceName,
    required this.lastSeen,
    this.isConnected = true,
  });
}
