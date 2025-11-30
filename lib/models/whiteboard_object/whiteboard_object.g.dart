// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whiteboard_object.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WhiteboardObjectImpl _$$WhiteboardObjectImplFromJson(
        Map<String, dynamic> json) =>
    _$WhiteboardObjectImpl(
      id: json['id'] as String,
      type: $enumDecode(_$WhiteboardObjectTypeEnumMap, json['type']),
      data: json['data'] as Map<String, dynamic>,
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      version: (json['version'] as num?)?.toInt() ?? 0,
      createdBy: json['createdBy'] as String,
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
    );

Map<String, dynamic> _$$WhiteboardObjectImplToJson(
        _$WhiteboardObjectImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$WhiteboardObjectTypeEnumMap[instance.type]!,
      'data': instance.data,
      'zIndex': instance.zIndex,
      'version': instance.version,
      'createdBy': instance.createdBy,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

const _$WhiteboardObjectTypeEnumMap = {
  WhiteboardObjectType.path: 'path',
  WhiteboardObjectType.rectangle: 'rectangle',
  WhiteboardObjectType.circle: 'circle',
  WhiteboardObjectType.arrow: 'arrow',
  WhiteboardObjectType.stickyNote: 'stickyNote',
  WhiteboardObjectType.textBox: 'textBox',
  WhiteboardObjectType.taskNode: 'taskNode',
  WhiteboardObjectType.stroke: 'stroke',
  WhiteboardObjectType.task: 'task',
};

_$PathDataImpl _$$PathDataImplFromJson(Map<String, dynamic> json) =>
    _$PathDataImpl(
      points: const OffsetListConverter().fromJson(json['points'] as List),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      color: (json['color'] as num?)?.toInt() ?? 0xFF000000,
    );

Map<String, dynamic> _$$PathDataImplToJson(_$PathDataImpl instance) =>
    <String, dynamic>{
      'points': const OffsetListConverter().toJson(instance.points),
      'strokeWidth': instance.strokeWidth,
      'color': instance.color,
    };

_$ShapeDataImpl _$$ShapeDataImplFromJson(Map<String, dynamic> json) =>
    _$ShapeDataImpl(
      position: const OffsetConverter()
          .fromJson(json['position'] as Map<String, dynamic>),
      size:
          const SizeConverter().fromJson(json['size'] as Map<String, dynamic>),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 2.0,
      strokeColor: (json['strokeColor'] as num?)?.toInt() ?? 0xFF000000,
      fillColor: (json['fillColor'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$ShapeDataImplToJson(_$ShapeDataImpl instance) =>
    <String, dynamic>{
      'position': const OffsetConverter().toJson(instance.position),
      'size': const SizeConverter().toJson(instance.size),
      'strokeWidth': instance.strokeWidth,
      'strokeColor': instance.strokeColor,
      'fillColor': instance.fillColor,
    };

_$StickyNoteDataImpl _$$StickyNoteDataImplFromJson(Map<String, dynamic> json) =>
    _$StickyNoteDataImpl(
      position: const OffsetConverter()
          .fromJson(json['position'] as Map<String, dynamic>),
      size:
          const SizeConverter().fromJson(json['size'] as Map<String, dynamic>),
      text: json['text'] as String,
      color: (json['color'] as num?)?.toInt() ?? 0xFFFFF9C4,
    );

Map<String, dynamic> _$$StickyNoteDataImplToJson(
        _$StickyNoteDataImpl instance) =>
    <String, dynamic>{
      'position': const OffsetConverter().toJson(instance.position),
      'size': const SizeConverter().toJson(instance.size),
      'text': instance.text,
      'color': instance.color,
    };

_$TextBoxDataImpl _$$TextBoxDataImplFromJson(Map<String, dynamic> json) =>
    _$TextBoxDataImpl(
      position: const OffsetConverter()
          .fromJson(json['position'] as Map<String, dynamic>),
      text: json['text'] as String,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
      color: (json['color'] as num?)?.toInt() ?? 0xFF000000,
    );

Map<String, dynamic> _$$TextBoxDataImplToJson(_$TextBoxDataImpl instance) =>
    <String, dynamic>{
      'position': const OffsetConverter().toJson(instance.position),
      'text': instance.text,
      'fontSize': instance.fontSize,
      'color': instance.color,
    };

_$StrokeDataImpl _$$StrokeDataImplFromJson(Map<String, dynamic> json) =>
    _$StrokeDataImpl(
      points: (json['points'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble() ?? 3.0,
      color: (json['color'] as num?)?.toInt() ?? 0xFF000000,
    );

Map<String, dynamic> _$$StrokeDataImplToJson(_$StrokeDataImpl instance) =>
    <String, dynamic>{
      'points': instance.points,
      'strokeWidth': instance.strokeWidth,
      'color': instance.color,
    };

_$TaskDataImpl _$$TaskDataImplFromJson(Map<String, dynamic> json) =>
    _$TaskDataImpl(
      title: json['title'] as String?,
      assignee: json['assignee'] as String?,
      status: json['status'] as String? ?? 'todo',
      timestamp: (json['timestamp'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$TaskDataImplToJson(_$TaskDataImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'assignee': instance.assignee,
      'status': instance.status,
      'timestamp': instance.timestamp,
    };
