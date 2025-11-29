// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OperationImpl _$$OperationImplFromJson(Map<String, dynamic> json) =>
    _$OperationImpl(
      opId: json['opId'] as String,
      actor: json['actor'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      type: $enumDecode(_$OperationTypeEnumMap, json['type']),
      payload: json['payload'] as Map<String, dynamic>,
      applied: json['applied'] as bool? ?? false,
    );

Map<String, dynamic> _$$OperationImplToJson(_$OperationImpl instance) =>
    <String, dynamic>{
      'opId': instance.opId,
      'actor': instance.actor,
      'timestamp': instance.timestamp,
      'type': _$OperationTypeEnumMap[instance.type]!,
      'payload': instance.payload,
      'applied': instance.applied,
    };

const _$OperationTypeEnumMap = {
  OperationType.createObject: 'createObject',
  OperationType.updateObject: 'updateObject',
  OperationType.deleteObject: 'deleteObject',
  OperationType.moveObject: 'moveObject',
  OperationType.resizeObject: 'resizeObject',
};
