// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'peer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Peer _$PeerFromJson(Map<String, dynamic> json) {
  return _Peer.fromJson(json);
}

/// @nodoc
mixin _$Peer {
  String get socketId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  bool get connected => throw _privateConstructorUsedError;
  String? get userName =>
      throw _privateConstructorUsedError; // Tên hiển thị thật của người dùng
  String? get avatar => throw _privateConstructorUsedError; // URL avatar
  bool get isMuted => throw _privateConstructorUsedError;

  /// Serializes this Peer to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Peer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PeerCopyWith<Peer> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PeerCopyWith<$Res> {
  factory $PeerCopyWith(Peer value, $Res Function(Peer) then) =
      _$PeerCopyWithImpl<$Res, Peer>;
  @useResult
  $Res call({
    String socketId,
    String userId,
    bool connected,
    String? userName,
    String? avatar,
    bool isMuted,
  });
}

/// @nodoc
class _$PeerCopyWithImpl<$Res, $Val extends Peer>
    implements $PeerCopyWith<$Res> {
  _$PeerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Peer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? socketId = null,
    Object? userId = null,
    Object? connected = null,
    Object? userName = freezed,
    Object? avatar = freezed,
    Object? isMuted = null,
  }) {
    return _then(
      _value.copyWith(
            socketId: null == socketId
                ? _value.socketId
                : socketId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            connected: null == connected
                ? _value.connected
                : connected // ignore: cast_nullable_to_non_nullable
                      as bool,
            userName: freezed == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String?,
            avatar: freezed == avatar
                ? _value.avatar
                : avatar // ignore: cast_nullable_to_non_nullable
                      as String?,
            isMuted: null == isMuted
                ? _value.isMuted
                : isMuted // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PeerImplCopyWith<$Res> implements $PeerCopyWith<$Res> {
  factory _$$PeerImplCopyWith(
    _$PeerImpl value,
    $Res Function(_$PeerImpl) then,
  ) = __$$PeerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String socketId,
    String userId,
    bool connected,
    String? userName,
    String? avatar,
    bool isMuted,
  });
}

/// @nodoc
class __$$PeerImplCopyWithImpl<$Res>
    extends _$PeerCopyWithImpl<$Res, _$PeerImpl>
    implements _$$PeerImplCopyWith<$Res> {
  __$$PeerImplCopyWithImpl(_$PeerImpl _value, $Res Function(_$PeerImpl) _then)
    : super(_value, _then);

  /// Create a copy of Peer
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? socketId = null,
    Object? userId = null,
    Object? connected = null,
    Object? userName = freezed,
    Object? avatar = freezed,
    Object? isMuted = null,
  }) {
    return _then(
      _$PeerImpl(
        socketId: null == socketId
            ? _value.socketId
            : socketId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        connected: null == connected
            ? _value.connected
            : connected // ignore: cast_nullable_to_non_nullable
                  as bool,
        userName: freezed == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String?,
        avatar: freezed == avatar
            ? _value.avatar
            : avatar // ignore: cast_nullable_to_non_nullable
                  as String?,
        isMuted: null == isMuted
            ? _value.isMuted
            : isMuted // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PeerImpl implements _Peer {
  const _$PeerImpl({
    required this.socketId,
    required this.userId,
    this.connected = false,
    this.userName,
    this.avatar,
    this.isMuted = false,
  });

  factory _$PeerImpl.fromJson(Map<String, dynamic> json) =>
      _$$PeerImplFromJson(json);

  @override
  final String socketId;
  @override
  final String userId;
  @override
  @JsonKey()
  final bool connected;
  @override
  final String? userName;
  // Tên hiển thị thật của người dùng
  @override
  final String? avatar;
  // URL avatar
  @override
  @JsonKey()
  final bool isMuted;

  @override
  String toString() {
    return 'Peer(socketId: $socketId, userId: $userId, connected: $connected, userName: $userName, avatar: $avatar, isMuted: $isMuted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PeerImpl &&
            (identical(other.socketId, socketId) ||
                other.socketId == socketId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.connected, connected) ||
                other.connected == connected) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.isMuted, isMuted) || other.isMuted == isMuted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    socketId,
    userId,
    connected,
    userName,
    avatar,
    isMuted,
  );

  /// Create a copy of Peer
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PeerImplCopyWith<_$PeerImpl> get copyWith =>
      __$$PeerImplCopyWithImpl<_$PeerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PeerImplToJson(this);
  }
}

abstract class _Peer implements Peer {
  const factory _Peer({
    required final String socketId,
    required final String userId,
    final bool connected,
    final String? userName,
    final String? avatar,
    final bool isMuted,
  }) = _$PeerImpl;

  factory _Peer.fromJson(Map<String, dynamic> json) = _$PeerImpl.fromJson;

  @override
  String get socketId;
  @override
  String get userId;
  @override
  bool get connected;
  @override
  String? get userName; // Tên hiển thị thật của người dùng
  @override
  String? get avatar; // URL avatar
  @override
  bool get isMuted;

  /// Create a copy of Peer
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PeerImplCopyWith<_$PeerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
