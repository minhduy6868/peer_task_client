import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../converters.dart';

part 'whiteboard_object.freezed.dart';
part 'whiteboard_object.g.dart';

enum WhiteboardObjectType {
  path,
  rectangle,
  circle,
  arrow,
  stickyNote,
  textBox,
  taskNode,
  stroke,      // Canvas drawing stroke
  task,        // Kanban task
}

@freezed
class WhiteboardObject with _$WhiteboardObject {
  const factory WhiteboardObject({
    required String id,
    required WhiteboardObjectType type,
    required Map<String, dynamic> data,
    @Default(0) int zIndex,
    @Default(0) int version,
    required String createdBy,
    required int createdAt,
    required int updatedAt,
  }) = _WhiteboardObject;

  factory WhiteboardObject.fromJson(Map<String, dynamic> json) => _$WhiteboardObjectFromJson(json);
}

// Specific object data structures

@freezed
class PathData with _$PathData {
  const factory PathData({
    @OffsetListConverter() required List<Offset> points,
    @Default(2.0) double strokeWidth,
    @Default(0xFF000000) int color,
  }) = _PathData;

  factory PathData.fromJson(Map<String, dynamic> json) => _$PathDataFromJson(json);
}

@freezed
class ShapeData with _$ShapeData {
  const factory ShapeData({
    @OffsetConverter() required Offset position,
    @SizeConverter() required Size size,
    @Default(2.0) double strokeWidth,
    @Default(0xFF000000) int strokeColor,
    int? fillColor,
  }) = _ShapeData;

  factory ShapeData.fromJson(Map<String, dynamic> json) => _$ShapeDataFromJson(json);
}

@freezed
class StickyNoteData with _$StickyNoteData {
  const factory StickyNoteData({
    @OffsetConverter() required Offset position,
    @SizeConverter() required Size size,
    required String text,
    @Default(0xFFFFF9C4) int color,
  }) = _StickyNoteData;

  factory StickyNoteData.fromJson(Map<String, dynamic> json) => _$StickyNoteDataFromJson(json);
}

@freezed
class TextBoxData with _$TextBoxData {
  const factory TextBoxData({
    @OffsetConverter() required Offset position,
    required String text,
    @Default(16.0) double fontSize,
    @Default(0xFF000000) int color,
  }) = _TextBoxData;

  factory TextBoxData.fromJson(Map<String, dynamic> json) => _$TextBoxDataFromJson(json);
}

@freezed
class StrokeData with _$StrokeData {
  const factory StrokeData({
    required List<double> points,
    @Default(3.0) double strokeWidth,
    @Default(0xFF000000) int color,
  }) = _StrokeData;

  factory StrokeData.fromJson(Map<String, dynamic> json) => _$StrokeDataFromJson(json);
}

@freezed
class TaskData with _$TaskData {
  const factory TaskData({
    String? title,  // Made nullable for backwards compatibility
    String? assignee,  // Deprecated, kept for backwards compatibility
    @Default('todo') String status,
    int? timestamp,
  }) = _TaskData;

  factory TaskData.fromJson(Map<String, dynamic> json) => _$TaskDataFromJson(json);
}
