import 'package:freezed_annotation/freezed_annotation.dart';

part 'board.freezed.dart';

@freezed
class Board with _$Board {
  const factory Board({
    required String id,
    required String workspaceId,
    required String name,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Board;

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['id'] as String,
      workspaceId: json['workspace_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
