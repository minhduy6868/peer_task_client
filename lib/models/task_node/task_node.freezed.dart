// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_node.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TaskNode _$TaskNodeFromJson(Map<String, dynamic> json) {
  return _TaskNode.fromJson(json);
}

/// @nodoc
mixin _$TaskNode {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get assigneeId => throw _privateConstructorUsedError;
  DateTime? get deadline => throw _privateConstructorUsedError;
  int get progress => throw _privateConstructorUsedError;
  String get priority => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @OffsetConverter()
  Offset get position => throw _privateConstructorUsedError;
  @SizeConverter()
  Size get size => throw _privateConstructorUsedError;
  int get zIndex => throw _privateConstructorUsedError;
  int get version => throw _privateConstructorUsedError;
  int get color => throw _privateConstructorUsedError;

  /// Serializes this TaskNode to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaskNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskNodeCopyWith<TaskNode> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskNodeCopyWith<$Res> {
  factory $TaskNodeCopyWith(TaskNode value, $Res Function(TaskNode) then) =
      _$TaskNodeCopyWithImpl<$Res, TaskNode>;
  @useResult
  $Res call(
      {String id,
      String title,
      String? description,
      String? assigneeId,
      DateTime? deadline,
      int progress,
      String priority,
      String status,
      @OffsetConverter() Offset position,
      @SizeConverter() Size size,
      int zIndex,
      int version,
      int color});
}

/// @nodoc
class _$TaskNodeCopyWithImpl<$Res, $Val extends TaskNode>
    implements $TaskNodeCopyWith<$Res> {
  _$TaskNodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? assigneeId = freezed,
    Object? deadline = freezed,
    Object? progress = null,
    Object? priority = null,
    Object? status = null,
    Object? position = null,
    Object? size = null,
    Object? zIndex = null,
    Object? version = null,
    Object? color = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      assigneeId: freezed == assigneeId
          ? _value.assigneeId
          : assigneeId // ignore: cast_nullable_to_non_nullable
              as String?,
      deadline: freezed == deadline
          ? _value.deadline
          : deadline // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as int,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as Offset,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as Size,
      zIndex: null == zIndex
          ? _value.zIndex
          : zIndex // ignore: cast_nullable_to_non_nullable
              as int,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TaskNodeImplCopyWith<$Res>
    implements $TaskNodeCopyWith<$Res> {
  factory _$$TaskNodeImplCopyWith(
          _$TaskNodeImpl value, $Res Function(_$TaskNodeImpl) then) =
      __$$TaskNodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String? description,
      String? assigneeId,
      DateTime? deadline,
      int progress,
      String priority,
      String status,
      @OffsetConverter() Offset position,
      @SizeConverter() Size size,
      int zIndex,
      int version,
      int color});
}

/// @nodoc
class __$$TaskNodeImplCopyWithImpl<$Res>
    extends _$TaskNodeCopyWithImpl<$Res, _$TaskNodeImpl>
    implements _$$TaskNodeImplCopyWith<$Res> {
  __$$TaskNodeImplCopyWithImpl(
      _$TaskNodeImpl _value, $Res Function(_$TaskNodeImpl) _then)
      : super(_value, _then);

  /// Create a copy of TaskNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? assigneeId = freezed,
    Object? deadline = freezed,
    Object? progress = null,
    Object? priority = null,
    Object? status = null,
    Object? position = null,
    Object? size = null,
    Object? zIndex = null,
    Object? version = null,
    Object? color = null,
  }) {
    return _then(_$TaskNodeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      assigneeId: freezed == assigneeId
          ? _value.assigneeId
          : assigneeId // ignore: cast_nullable_to_non_nullable
              as String?,
      deadline: freezed == deadline
          ? _value.deadline
          : deadline // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as int,
      priority: null == priority
          ? _value.priority
          : priority // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as Offset,
      size: null == size
          ? _value.size
          : size // ignore: cast_nullable_to_non_nullable
              as Size,
      zIndex: null == zIndex
          ? _value.zIndex
          : zIndex // ignore: cast_nullable_to_non_nullable
              as int,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskNodeImpl implements _TaskNode {
  const _$TaskNodeImpl(
      {required this.id,
      required this.title,
      this.description,
      this.assigneeId,
      this.deadline,
      this.progress = 0,
      this.priority = 'medium',
      this.status = 'todo',
      @OffsetConverter() required this.position,
      @SizeConverter() required this.size,
      this.zIndex = 0,
      this.version = 0,
      this.color = 0xFFFFEB3B});

  factory _$TaskNodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskNodeImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String? description;
  @override
  final String? assigneeId;
  @override
  final DateTime? deadline;
  @override
  @JsonKey()
  final int progress;
  @override
  @JsonKey()
  final String priority;
  @override
  @JsonKey()
  final String status;
  @override
  @OffsetConverter()
  final Offset position;
  @override
  @SizeConverter()
  final Size size;
  @override
  @JsonKey()
  final int zIndex;
  @override
  @JsonKey()
  final int version;
  @override
  @JsonKey()
  final int color;

  @override
  String toString() {
    return 'TaskNode(id: $id, title: $title, description: $description, assigneeId: $assigneeId, deadline: $deadline, progress: $progress, priority: $priority, status: $status, position: $position, size: $size, zIndex: $zIndex, version: $version, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskNodeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.assigneeId, assigneeId) ||
                other.assigneeId == assigneeId) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.zIndex, zIndex) || other.zIndex == zIndex) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.color, color) || other.color == color));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      assigneeId,
      deadline,
      progress,
      priority,
      status,
      position,
      size,
      zIndex,
      version,
      color);

  /// Create a copy of TaskNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskNodeImplCopyWith<_$TaskNodeImpl> get copyWith =>
      __$$TaskNodeImplCopyWithImpl<_$TaskNodeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskNodeImplToJson(
      this,
    );
  }
}

abstract class _TaskNode implements TaskNode {
  const factory _TaskNode(
      {required final String id,
      required final String title,
      final String? description,
      final String? assigneeId,
      final DateTime? deadline,
      final int progress,
      final String priority,
      final String status,
      @OffsetConverter() required final Offset position,
      @SizeConverter() required final Size size,
      final int zIndex,
      final int version,
      final int color}) = _$TaskNodeImpl;

  factory _TaskNode.fromJson(Map<String, dynamic> json) =
      _$TaskNodeImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String? get description;
  @override
  String? get assigneeId;
  @override
  DateTime? get deadline;
  @override
  int get progress;
  @override
  String get priority;
  @override
  String get status;
  @override
  @OffsetConverter()
  Offset get position;
  @override
  @SizeConverter()
  Size get size;
  @override
  int get zIndex;
  @override
  int get version;
  @override
  int get color;

  /// Create a copy of TaskNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskNodeImplCopyWith<_$TaskNodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
