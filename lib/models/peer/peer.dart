import 'package:freezed_annotation/freezed_annotation.dart';

part 'peer.freezed.dart';
part 'peer.g.dart';

@freezed
class Peer with _$Peer {
  const factory Peer({
    required String socketId,
    required String userId,
    @Default(false) bool connected,
    String? userName,  // Tên hiển thị thật của người dùng
    String? avatar,    // URL avatar
    @Default(false) bool isMuted,  // Trạng thái mic
  }) = _Peer;

  factory Peer.fromJson(Map<String, dynamic> json) => _$PeerFromJson(json);
}
