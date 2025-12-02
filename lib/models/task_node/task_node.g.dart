// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskNodeImpl _$$TaskNodeImplFromJson(Map<String, dynamic> json) =>
    _$TaskNodeImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      assigneeId: json['assigneeId'] as String?,
      deadline: json['deadline'] == null
          ? null
          : DateTime.parse(json['deadline'] as String),
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'todo',
      position: const OffsetConverter().fromJson(
        json['position'] as Map<String, dynamic>,
      ),
      size: const SizeConverter().fromJson(
        json['size'] as Map<String, dynamic>,
      ),
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      version: (json['version'] as num?)?.toInt() ?? 0,
      color: (json['color'] as num?)?.toInt() ?? 0xFFFFEB3B,
    );

Map<String, dynamic> _$$TaskNodeImplToJson(_$TaskNodeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'assigneeId': instance.assigneeId,
      'deadline': instance.deadline?.toIso8601String(),
      'progress': instance.progress,
      'priority': instance.priority,
      'status': instance.status,
      'position': const OffsetConverter().toJson(instance.position),
      'size': const SizeConverter().toJson(instance.size),
      'zIndex': instance.zIndex,
      'version': instance.version,
      'color': instance.color,
    };
