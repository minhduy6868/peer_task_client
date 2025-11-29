import 'package:freezed_annotation/freezed_annotation.dart';

part 'operation.freezed.dart';
part 'operation.g.dart';

enum OperationType {
  createObject,
  updateObject,
  deleteObject,
  moveObject,
  resizeObject,
}

@freezed
class Operation with _$Operation {
  const factory Operation({
    required String opId,
    required String actor,
    required int timestamp,
    required OperationType type,
    required Map<String, dynamic> payload,
    @Default(false) bool applied,
  }) = _Operation;

  factory Operation.fromJson(Map<String, dynamic> json) => _$OperationFromJson(json);
}
