// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'peer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PeerImpl _$$PeerImplFromJson(Map<String, dynamic> json) => _$PeerImpl(
  socketId: json['socketId'] as String,
  userId: json['userId'] as String,
  connected: json['connected'] as bool? ?? false,
);

Map<String, dynamic> _$$PeerImplToJson(_$PeerImpl instance) =>
    <String, dynamic>{
      'socketId': instance.socketId,
      'userId': instance.userId,
      'connected': instance.connected,
    };
