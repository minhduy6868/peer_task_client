// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TaskModel _$TaskModelFromJson(Map<String, dynamic> json) {
  return _TaskModel.fromJson(json);
}

/// @nodoc
mixin _$TaskModel {
  String get id => throw _privateConstructorUsedError;
  String get boardId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // 'todo', 'doing', 'done'
  String get priority =>
      throw _privateConstructorUsedError; // 'low', 'medium', 'high', 'urgent'
  List<String> get assignees => throw _privateConstructorUsedError; // User IDs
  List<AssigneeInfo> get assigneeList =>
      throw _privateConstructorUsedError; // Full user info
  List<String> get labels => throw _privateConstructorUsedError; // Label names
  DateTime? get deadline => throw _privateConstructorUsedError;
  double? get estimatedHours => throw _privateConstructorUsedError;
  double? get actualHours => throw _privateConstructorUsedError;
  String? get parentId => throw _privateConstructorUsedError;
  int get position => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  String? get creatorName => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this TaskModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskModelCopyWith<TaskModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskModelCopyWith<$Res> {
  factory $TaskModelCopyWith(TaskModel value, $Res Function(TaskModel) then) =
      _$TaskModelCopyWithImpl<$Res, TaskModel>;
  @useResult
  $Res call({
    String id,
    String boardId,
    String title,
    String? description,
    String status,
    String priority,
    List<String> assignees,
    List<AssigneeInfo> assigneeList,
    List<String> labels,
    DateTime? deadline,
    double? estimatedHours,
    double? actualHours,
    String? parentId,
    int position,
    String createdBy,
    String? creatorName,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$TaskModelCopyWithImpl<$Res, $Val extends TaskModel>
    implements $TaskModelCopyWith<$Res> {
  _$TaskModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? boardId = null,
    Object? title = null,
    Object? description = freezed,
    Object? status = null,
    Object? priority = null,
    Object? assignees = null,
    Object? assigneeList = null,
    Object? labels = null,
    Object? deadline = freezed,
    Object? estimatedHours = freezed,
    Object? actualHours = freezed,
    Object? parentId = freezed,
    Object? position = null,
    Object? createdBy = null,
    Object? creatorName = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            boardId: null == boardId
                ? _value.boardId
                : boardId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as String,
            assignees: null == assignees
                ? _value.assignees
                : assignees // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            assigneeList: null == assigneeList
                ? _value.assigneeList
                : assigneeList // ignore: cast_nullable_to_non_nullable
                      as List<AssigneeInfo>,
            labels: null == labels
                ? _value.labels
                : labels // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            deadline: freezed == deadline
                ? _value.deadline
                : deadline // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            estimatedHours: freezed == estimatedHours
                ? _value.estimatedHours
                : estimatedHours // ignore: cast_nullable_to_non_nullable
                      as double?,
            actualHours: freezed == actualHours
                ? _value.actualHours
                : actualHours // ignore: cast_nullable_to_non_nullable
                      as double?,
            parentId: freezed == parentId
                ? _value.parentId
                : parentId // ignore: cast_nullable_to_non_nullable
                      as String?,
            position: null == position
                ? _value.position
                : position // ignore: cast_nullable_to_non_nullable
                      as int,
            createdBy: null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String,
            creatorName: freezed == creatorName
                ? _value.creatorName
                : creatorName // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TaskModelImplCopyWith<$Res>
    implements $TaskModelCopyWith<$Res> {
  factory _$$TaskModelImplCopyWith(
    _$TaskModelImpl value,
    $Res Function(_$TaskModelImpl) then,
  ) = __$$TaskModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String boardId,
    String title,
    String? description,
    String status,
    String priority,
    List<String> assignees,
    List<AssigneeInfo> assigneeList,
    List<String> labels,
    DateTime? deadline,
    double? estimatedHours,
    double? actualHours,
    String? parentId,
    int position,
    String createdBy,
    String? creatorName,
    DateTime createdAt,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$TaskModelImplCopyWithImpl<$Res>
    extends _$TaskModelCopyWithImpl<$Res, _$TaskModelImpl>
    implements _$$TaskModelImplCopyWith<$Res> {
  __$$TaskModelImplCopyWithImpl(
    _$TaskModelImpl _value,
    $Res Function(_$TaskModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? boardId = null,
    Object? title = null,
    Object? description = freezed,
    Object? status = null,
    Object? priority = null,
    Object? assignees = null,
    Object? assigneeList = null,
    Object? labels = null,
    Object? deadline = freezed,
    Object? estimatedHours = freezed,
    Object? actualHours = freezed,
    Object? parentId = freezed,
    Object? position = null,
    Object? createdBy = null,
    Object? creatorName = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$TaskModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        boardId: null == boardId
            ? _value.boardId
            : boardId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as String,
        assignees: null == assignees
            ? _value._assignees
            : assignees // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        assigneeList: null == assigneeList
            ? _value._assigneeList
            : assigneeList // ignore: cast_nullable_to_non_nullable
                  as List<AssigneeInfo>,
        labels: null == labels
            ? _value._labels
            : labels // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        deadline: freezed == deadline
            ? _value.deadline
            : deadline // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        estimatedHours: freezed == estimatedHours
            ? _value.estimatedHours
            : estimatedHours // ignore: cast_nullable_to_non_nullable
                  as double?,
        actualHours: freezed == actualHours
            ? _value.actualHours
            : actualHours // ignore: cast_nullable_to_non_nullable
                  as double?,
        parentId: freezed == parentId
            ? _value.parentId
            : parentId // ignore: cast_nullable_to_non_nullable
                  as String?,
        position: null == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as int,
        createdBy: null == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String,
        creatorName: freezed == creatorName
            ? _value.creatorName
            : creatorName // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskModelImpl implements _TaskModel {
  const _$TaskModelImpl({
    required this.id,
    required this.boardId,
    required this.title,
    this.description,
    this.status = 'todo',
    this.priority = 'medium',
    final List<String> assignees = const [],
    final List<AssigneeInfo> assigneeList = const [],
    final List<String> labels = const [],
    this.deadline,
    this.estimatedHours,
    this.actualHours,
    this.parentId,
    this.position = 0,
    required this.createdBy,
    this.creatorName,
    required this.createdAt,
    required this.updatedAt,
  }) : _assignees = assignees,
       _assigneeList = assigneeList,
       _labels = labels;

  factory _$TaskModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskModelImplFromJson(json);

  @override
  final String id;
  @override
  final String boardId;
  @override
  final String title;
  @override
  final String? description;
  @override
  @JsonKey()
  final String status;
  // 'todo', 'doing', 'done'
  @override
  @JsonKey()
  final String priority;
  // 'low', 'medium', 'high', 'urgent'
  final List<String> _assignees;
  // 'low', 'medium', 'high', 'urgent'
  @override
  @JsonKey()
  List<String> get assignees {
    if (_assignees is EqualUnmodifiableListView) return _assignees;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assignees);
  }

  // User IDs
  final List<AssigneeInfo> _assigneeList;
  // User IDs
  @override
  @JsonKey()
  List<AssigneeInfo> get assigneeList {
    if (_assigneeList is EqualUnmodifiableListView) return _assigneeList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_assigneeList);
  }

  // Full user info
  final List<String> _labels;
  // Full user info
  @override
  @JsonKey()
  List<String> get labels {
    if (_labels is EqualUnmodifiableListView) return _labels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_labels);
  }

  // Label names
  @override
  final DateTime? deadline;
  @override
  final double? estimatedHours;
  @override
  final double? actualHours;
  @override
  final String? parentId;
  @override
  @JsonKey()
  final int position;
  @override
  final String createdBy;
  @override
  final String? creatorName;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'TaskModel(id: $id, boardId: $boardId, title: $title, description: $description, status: $status, priority: $priority, assignees: $assignees, assigneeList: $assigneeList, labels: $labels, deadline: $deadline, estimatedHours: $estimatedHours, actualHours: $actualHours, parentId: $parentId, position: $position, createdBy: $createdBy, creatorName: $creatorName, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.boardId, boardId) || other.boardId == boardId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            const DeepCollectionEquality().equals(
              other._assignees,
              _assignees,
            ) &&
            const DeepCollectionEquality().equals(
              other._assigneeList,
              _assigneeList,
            ) &&
            const DeepCollectionEquality().equals(other._labels, _labels) &&
            (identical(other.deadline, deadline) ||
                other.deadline == deadline) &&
            (identical(other.estimatedHours, estimatedHours) ||
                other.estimatedHours == estimatedHours) &&
            (identical(other.actualHours, actualHours) ||
                other.actualHours == actualHours) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.creatorName, creatorName) ||
                other.creatorName == creatorName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    boardId,
    title,
    description,
    status,
    priority,
    const DeepCollectionEquality().hash(_assignees),
    const DeepCollectionEquality().hash(_assigneeList),
    const DeepCollectionEquality().hash(_labels),
    deadline,
    estimatedHours,
    actualHours,
    parentId,
    position,
    createdBy,
    creatorName,
    createdAt,
    updatedAt,
  );

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskModelImplCopyWith<_$TaskModelImpl> get copyWith =>
      __$$TaskModelImplCopyWithImpl<_$TaskModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskModelImplToJson(this);
  }
}

abstract class _TaskModel implements TaskModel {
  const factory _TaskModel({
    required final String id,
    required final String boardId,
    required final String title,
    final String? description,
    final String status,
    final String priority,
    final List<String> assignees,
    final List<AssigneeInfo> assigneeList,
    final List<String> labels,
    final DateTime? deadline,
    final double? estimatedHours,
    final double? actualHours,
    final String? parentId,
    final int position,
    required final String createdBy,
    final String? creatorName,
    required final DateTime createdAt,
    required final DateTime updatedAt,
  }) = _$TaskModelImpl;

  factory _TaskModel.fromJson(Map<String, dynamic> json) =
      _$TaskModelImpl.fromJson;

  @override
  String get id;
  @override
  String get boardId;
  @override
  String get title;
  @override
  String? get description;
  @override
  String get status; // 'todo', 'doing', 'done'
  @override
  String get priority; // 'low', 'medium', 'high', 'urgent'
  @override
  List<String> get assignees; // User IDs
  @override
  List<AssigneeInfo> get assigneeList; // Full user info
  @override
  List<String> get labels; // Label names
  @override
  DateTime? get deadline;
  @override
  double? get estimatedHours;
  @override
  double? get actualHours;
  @override
  String? get parentId;
  @override
  int get position;
  @override
  String get createdBy;
  @override
  String? get creatorName;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskModelImplCopyWith<_$TaskModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AssigneeInfo _$AssigneeInfoFromJson(Map<String, dynamic> json) {
  return _AssigneeInfo.fromJson(json);
}

/// @nodoc
mixin _$AssigneeInfo {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get avatar => throw _privateConstructorUsedError;

  /// Serializes this AssigneeInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AssigneeInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AssigneeInfoCopyWith<AssigneeInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AssigneeInfoCopyWith<$Res> {
  factory $AssigneeInfoCopyWith(
    AssigneeInfo value,
    $Res Function(AssigneeInfo) then,
  ) = _$AssigneeInfoCopyWithImpl<$Res, AssigneeInfo>;
  @useResult
  $Res call({String id, String name, String? email, String? avatar});
}

/// @nodoc
class _$AssigneeInfoCopyWithImpl<$Res, $Val extends AssigneeInfo>
    implements $AssigneeInfoCopyWith<$Res> {
  _$AssigneeInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AssigneeInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? email = freezed,
    Object? avatar = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            avatar: freezed == avatar
                ? _value.avatar
                : avatar // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AssigneeInfoImplCopyWith<$Res>
    implements $AssigneeInfoCopyWith<$Res> {
  factory _$$AssigneeInfoImplCopyWith(
    _$AssigneeInfoImpl value,
    $Res Function(_$AssigneeInfoImpl) then,
  ) = __$$AssigneeInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String name, String? email, String? avatar});
}

/// @nodoc
class __$$AssigneeInfoImplCopyWithImpl<$Res>
    extends _$AssigneeInfoCopyWithImpl<$Res, _$AssigneeInfoImpl>
    implements _$$AssigneeInfoImplCopyWith<$Res> {
  __$$AssigneeInfoImplCopyWithImpl(
    _$AssigneeInfoImpl _value,
    $Res Function(_$AssigneeInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AssigneeInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? email = freezed,
    Object? avatar = freezed,
  }) {
    return _then(
      _$AssigneeInfoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        avatar: freezed == avatar
            ? _value.avatar
            : avatar // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AssigneeInfoImpl implements _AssigneeInfo {
  const _$AssigneeInfoImpl({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
  });

  factory _$AssigneeInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AssigneeInfoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? email;
  @override
  final String? avatar;

  @override
  String toString() {
    return 'AssigneeInfo(id: $id, name: $name, email: $email, avatar: $avatar)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AssigneeInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.avatar, avatar) || other.avatar == avatar));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, email, avatar);

  /// Create a copy of AssigneeInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AssigneeInfoImplCopyWith<_$AssigneeInfoImpl> get copyWith =>
      __$$AssigneeInfoImplCopyWithImpl<_$AssigneeInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AssigneeInfoImplToJson(this);
  }
}

abstract class _AssigneeInfo implements AssigneeInfo {
  const factory _AssigneeInfo({
    required final String id,
    required final String name,
    final String? email,
    final String? avatar,
  }) = _$AssigneeInfoImpl;

  factory _AssigneeInfo.fromJson(Map<String, dynamic> json) =
      _$AssigneeInfoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get email;
  @override
  String? get avatar;

  /// Create a copy of AssigneeInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AssigneeInfoImplCopyWith<_$AssigneeInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
