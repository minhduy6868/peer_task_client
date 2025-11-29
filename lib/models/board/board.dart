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
    String? permission, // 'edit' or 'view' - user's permission on this board
    bool? isBoardOwner, // Whether current user is the board owner
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
      permission: json['permission'] as String?, // User's permission: 'edit' or 'view'
      isBoardOwner: json['is_board_owner'] as bool?, // Whether user is the board owner
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}
