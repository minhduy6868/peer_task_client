import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'converters.dart';

part 'task_node.freezed.dart';
part 'task_node.g.dart';

@freezed
class TaskNode with _$TaskNode {
  const factory TaskNode({
    required String id,
    required String title,
    String? description,
    String? assigneeId,
    DateTime? deadline,
    @Default(0) int progress,
    @Default('medium') String priority,
    @Default('todo') String status,
    @OffsetConverter() required Offset position,
    @SizeConverter() required Size size,
    @Default(0) int zIndex,
    @Default(0) int version,
    @Default(0xFFFFEB3B) int color,
  }) = _TaskNode;

  factory TaskNode.fromJson(Map<String, dynamic> json) => _$TaskNodeFromJson(json);
}
