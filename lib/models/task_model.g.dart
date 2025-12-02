// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskModelImpl _$$TaskModelImplFromJson(
  Map<String, dynamic> json,
) => _$TaskModelImpl(
  id: json['id'] as String,
  boardId: json['boardId'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  status: json['status'] as String? ?? 'todo',
  priority: json['priority'] as String? ?? 'medium',
  assignees:
      (json['assignees'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  assigneeList:
      (json['assigneeList'] as List<dynamic>?)
          ?.map((e) => AssigneeInfo.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  labels:
      (json['labels'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  deadline: json['deadline'] == null
      ? null
      : DateTime.parse(json['deadline'] as String),
  estimatedHours: (json['estimatedHours'] as num?)?.toDouble(),
  actualHours: (json['actualHours'] as num?)?.toDouble(),
  parentId: json['parentId'] as String?,
  position: (json['position'] as num?)?.toInt() ?? 0,
  createdBy: json['createdBy'] as String,
  creatorName: json['creatorName'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$TaskModelImplToJson(_$TaskModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'boardId': instance.boardId,
      'title': instance.title,
      'description': instance.description,
      'status': instance.status,
      'priority': instance.priority,
      'assignees': instance.assignees,
      'assigneeList': instance.assigneeList,
      'labels': instance.labels,
      'deadline': instance.deadline?.toIso8601String(),
      'estimatedHours': instance.estimatedHours,
      'actualHours': instance.actualHours,
      'parentId': instance.parentId,
      'position': instance.position,
      'createdBy': instance.createdBy,
      'creatorName': instance.creatorName,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

_$AssigneeInfoImpl _$$AssigneeInfoImplFromJson(Map<String, dynamic> json) =>
    _$AssigneeInfoImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      avatar: json['avatar'] as String?,
    );

Map<String, dynamic> _$$AssigneeInfoImplToJson(_$AssigneeInfoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'avatar': instance.avatar,
    };
