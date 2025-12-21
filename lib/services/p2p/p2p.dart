/// P2P Services for offline collaboration
/// 
/// Use P2PManager as the main entry point:
/// ```dart
/// final p2p = P2PManager.create(
///   boardId: 'my-board-id',
///   userId: 'user-123',
///   deviceName: 'My Device',
/// );
/// 
/// p2p.onPeerJoined = (peerId, name) => print('Peer joined: $name');
/// p2p.onOperationReceived = (op) => applyOperation(op);
/// 
/// await p2p.start();
/// ```

export 'p2p_service_interface.dart';
export 'p2p_manager.dart';
