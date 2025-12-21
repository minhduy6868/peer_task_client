// Stub file for non-web platforms
// This file is imported when dart:io is available (not web)

class WebP2PService {
  final String boardId;
  final String peerId;
  final Function(String senderId, Map<String, dynamic> data)? onMessageReceived;
  final Function(String peerId)? onPeerJoined;
  final Function(String peerId)? onPeerLeft;
  
  WebP2PService({
    required this.boardId,
    required this.peerId,
    this.onMessageReceived,
    this.onPeerJoined,
    this.onPeerLeft,
  });
  
  Future<void> start() async {}
  Future<void> stop() async {}
  void broadcast(Map<String, dynamic> data) {}
  void sendBoardData(Map<String, dynamic> boardData) {}
  void sendOperation(Map<String, dynamic> operation) {}
  List<String> get connectedPeers => [];
  bool get isRunning => false;
  int get peerCount => 0;
}
