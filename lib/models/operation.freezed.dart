// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'operation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Operation _$OperationFromJson(Map<String, dynamic> json) {
  return _Operation.fromJson(json);
}

/// @nodoc
mixin _$Operation {
  String get opId => throw _privateConstructorUsedError;
  String get actor => throw _privateConstructorUsedError;
  int get timestamp => throw _privateConstructorUsedError;
  OperationType get type => throw _privateConstructorUsedError;
  Map<String, dynamic> get payload => throw _privateConstructorUsedError;
  bool get applied => throw _privateConstructorUsedError;

  /// Serializes this Operation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Operation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OperationCopyWith<Operation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OperationCopyWith<$Res> {
  factory $OperationCopyWith(Operation value, $Res Function(Operation) then) =
      _$OperationCopyWithImpl<$Res, Operation>;
  @useResult
  $Res call(
      {String opId,
      String actor,
      int timestamp,
      OperationType type,
      Map<String, dynamic> payload,
      bool applied});
}

/// @nodoc
class _$OperationCopyWithImpl<$Res, $Val extends Operation>
    implements $OperationCopyWith<$Res> {
  _$OperationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Operation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? opId = null,
    Object? actor = null,
    Object? timestamp = null,
    Object? type = null,
    Object? payload = null,
    Object? applied = null,
  }) {
    return _then(_value.copyWith(
      opId: null == opId
          ? _value.opId
          : opId // ignore: cast_nullable_to_non_nullable
              as String,
      actor: null == actor
          ? _value.actor
          : actor // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as int,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as OperationType,
      payload: null == payload
          ? _value.payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      applied: null == applied
          ? _value.applied
          : applied // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OperationImplCopyWith<$Res>
    implements $OperationCopyWith<$Res> {
  factory _$$OperationImplCopyWith(
          _$OperationImpl value, $Res Function(_$OperationImpl) then) =
      __$$OperationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String opId,
      String actor,
      int timestamp,
      OperationType type,
      Map<String, dynamic> payload,
      bool applied});
}

/// @nodoc
class __$$OperationImplCopyWithImpl<$Res>
    extends _$OperationCopyWithImpl<$Res, _$OperationImpl>
    implements _$$OperationImplCopyWith<$Res> {
  __$$OperationImplCopyWithImpl(
      _$OperationImpl _value, $Res Function(_$OperationImpl) _then)
      : super(_value, _then);

  /// Create a copy of Operation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? opId = null,
    Object? actor = null,
    Object? timestamp = null,
    Object? type = null,
    Object? payload = null,
    Object? applied = null,
  }) {
    return _then(_$OperationImpl(
      opId: null == opId
          ? _value.opId
          : opId // ignore: cast_nullable_to_non_nullable
              as String,
      actor: null == actor
          ? _value.actor
          : actor // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as int,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as OperationType,
      payload: null == payload
          ? _value._payload
          : payload // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      applied: null == applied
          ? _value.applied
          : applied // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OperationImpl implements _Operation {
  const _$OperationImpl(
      {required this.opId,
      required this.actor,
      required this.timestamp,
      required this.type,
      required final Map<String, dynamic> payload,
      this.applied = false})
      : _payload = payload;

  factory _$OperationImpl.fromJson(Map<String, dynamic> json) =>
      _$$OperationImplFromJson(json);

  @override
  final String opId;
  @override
  final String actor;
  @override
  final int timestamp;
  @override
  final OperationType type;
  final Map<String, dynamic> _payload;
  @override
  Map<String, dynamic> get payload {
    if (_payload is EqualUnmodifiableMapView) return _payload;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payload);
  }

  @override
  @JsonKey()
  final bool applied;

  @override
  String toString() {
    return 'Operation(opId: $opId, actor: $actor, timestamp: $timestamp, type: $type, payload: $payload, applied: $applied)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OperationImpl &&
            (identical(other.opId, opId) || other.opId == opId) &&
            (identical(other.actor, actor) || other.actor == actor) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other._payload, _payload) &&
            (identical(other.applied, applied) || other.applied == applied));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, opId, actor, timestamp, type,
      const DeepCollectionEquality().hash(_payload), applied);

  /// Create a copy of Operation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OperationImplCopyWith<_$OperationImpl> get copyWith =>
      __$$OperationImplCopyWithImpl<_$OperationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OperationImplToJson(
      this,
    );
  }
}

abstract class _Operation implements Operation {
  const factory _Operation(
      {required final String opId,
      required final String actor,
      required final int timestamp,
      required final OperationType type,
      required final Map<String, dynamic> payload,
      final bool applied}) = _$OperationImpl;

  factory _Operation.fromJson(Map<String, dynamic> json) =
      _$OperationImpl.fromJson;

  @override
  String get opId;
  @override
  String get actor;
  @override
  int get timestamp;
  @override
  OperationType get type;
  @override
  Map<String, dynamic> get payload;
  @override
  bool get applied;

  /// Create a copy of Operation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OperationImplCopyWith<_$OperationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
