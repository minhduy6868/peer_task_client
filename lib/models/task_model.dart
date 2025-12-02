import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

@freezed
class TaskModel with _$TaskModel {
  const factory TaskModel({
    required String id,
    required String boardId,
    required String title,
    String? description,
    required String status, // 'todo', 'doing', 'done'
    required String priority, // 'low', 'medium', 'high', 'urgent'
    required List<String> assignees, // User IDs
    required List<AssigneeInfo> assigneeList, // Full user info
    required List<String> labels, // Label names
    DateTime? deadline,
    double? estimatedHours,
    double? actualHours,
    String? parentId,
    required int position,
    required String createdBy,
    String? creatorName,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TaskModel;

  factory TaskModel.fromJson(Map<String, dynamic> json) => _$TaskModelFromJson(json);
}

@freezed
class AssigneeInfo with _$AssigneeInfo {
  const factory AssigneeInfo({
    required String id,
    required String name,
    String? email,
    String? avatar,
  }) = _AssigneeInfo;

  factory AssigneeInfo.fromJson(Map<String, dynamic> json) => _$AssigneeInfoFromJson(json);
}
