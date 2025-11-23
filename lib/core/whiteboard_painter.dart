import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/whiteboard_object.dart';
import '../models/task_node.dart';
import '../ui/widgets/drawing_toolbar.dart';

class WhiteboardPainter extends CustomPainter {
  final List<WhiteboardObject> objects;
  final List<TaskNode> taskNodes;
  final double zoom;
  final Offset pan;
  
  // Drawing in progress
  final List<Offset>? currentPoints;
  final Offset? startPoint;
  final Offset? endPoint;
  final DrawingTool? currentTool;
  final Color? currentColor;
  final double? currentStrokeWidth;

  WhiteboardPainter({
    required this.objects,
    this.taskNodes = const [],
    this.zoom = 1.0,
    this.pan = Offset.zero,
    this.currentPoints,
    this.startPoint,
    this.endPoint,
    this.currentTool,
    this.currentColor,
    this.currentStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Apply zoom and pan transformations
    canvas.save();
    canvas.translate(pan.dx, pan.dy);
    canvas.scale(zoom);

    // Draw grid
    _drawGrid(canvas, size);

    // Sort objects by z-index
    final sortedObjects = List<WhiteboardObject>.from(objects)
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    // Draw each object
    for (final obj in sortedObjects) {
      _drawObject(canvas, obj);
    }

    // Draw task nodes
    for (final taskNode in taskNodes) {
      _drawTaskNode(canvas, taskNode);
    }

    // Draw current drawing
    if (currentPoints != null && currentPoints!.isNotEmpty && currentTool != null) {
      _drawCurrentDrawing(canvas);
    }

    canvas.restore();
  }

  void _drawCurrentDrawing(Canvas canvas) {
    final paint = Paint()
      ..color = currentColor ?? Colors.black
      ..strokeWidth = currentStrokeWidth ?? 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    switch (currentTool!) {
      case DrawingTool.pen:
        if (currentPoints!.length > 1) {
          final path = Path();
          path.moveTo(currentPoints!.first.dx, currentPoints!.first.dy);
          for (int i = 1; i < currentPoints!.length; i++) {
            path.lineTo(currentPoints![i].dx, currentPoints![i].dy);
          }
          canvas.drawPath(path, paint);
        }
        break;

      case DrawingTool.rectangle:
        if (startPoint != null && endPoint != null) {
          final rect = Rect.fromPoints(startPoint!, endPoint!);
          canvas.drawRect(rect, paint);
        }
        break;

      case DrawingTool.circle:
        if (startPoint != null && endPoint != null) {
          final center = Offset(
            (startPoint!.dx + endPoint!.dx) / 2,
            (startPoint!.dy + endPoint!.dy) / 2,
          );
          final radius = (startPoint! - endPoint!).distance / 2;
          canvas.drawCircle(center, radius, paint);
        }
        break;

      case DrawingTool.line:
      case DrawingTool.arrow:
        if (startPoint != null && endPoint != null) {
          canvas.drawLine(startPoint!, endPoint!, paint);
          if (currentTool == DrawingTool.arrow) {
            _drawArrowhead(canvas, startPoint!, endPoint!, paint);
          }
        }
        break;

      default:
        break;
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1.0;

    const gridSize = 50.0;
    
    // Vertical lines
    for (double x = 0; x < size.width / zoom; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height / zoom),
        gridPaint,
      );
    }

    // Horizontal lines
    for (double y = 0; y < size.height / zoom; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width / zoom, y),
        gridPaint,
      );
    }
  }

  void _drawObject(Canvas canvas, WhiteboardObject obj) {
    switch (obj.type) {
      case WhiteboardObjectType.path:
        _drawPath(canvas, PathData.fromJson(obj.data));
        break;
      case WhiteboardObjectType.rectangle:
      case WhiteboardObjectType.circle:
        _drawShape(canvas, obj.type, ShapeData.fromJson(obj.data));
        break;
      case WhiteboardObjectType.arrow:
        _drawArrow(canvas, ShapeData.fromJson(obj.data));
        break;
      case WhiteboardObjectType.stickyNote:
        _drawStickyNote(canvas, StickyNoteData.fromJson(obj.data));
        break;
      case WhiteboardObjectType.textBox:
        _drawTextBox(canvas, TextBoxData.fromJson(obj.data));
        break;
      case WhiteboardObjectType.taskNode:
        // Task nodes are drawn separately
        break;
      case WhiteboardObjectType.stroke:
      case WhiteboardObjectType.task:
        // Handled by hybrid board, not whiteboard painter
        break;
    }
  }

  void _drawPath(Canvas canvas, PathData pathData) {
    if (pathData.points.isEmpty) return;

    final paint = Paint()
      ..color = Color(pathData.color)
      ..strokeWidth = pathData.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(pathData.points.first.dx, pathData.points.first.dy);

    for (int i = 1; i < pathData.points.length; i++) {
      path.lineTo(pathData.points[i].dx, pathData.points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  void _drawShape(Canvas canvas, WhiteboardObjectType type, ShapeData shapeData) {
    final strokePaint = Paint()
      ..color = Color(shapeData.strokeColor)
      ..strokeWidth = shapeData.strokeWidth
      ..style = PaintingStyle.stroke;

    Paint? fillPaint;
    if (shapeData.fillColor != null) {
      fillPaint = Paint()
        ..color = Color(shapeData.fillColor!)
        ..style = PaintingStyle.fill;
    }

    final rect = Rect.fromLTWH(
      shapeData.position.dx,
      shapeData.position.dy,
      shapeData.size.width,
      shapeData.size.height,
    );

    if (type == WhiteboardObjectType.rectangle) {
      if (fillPaint != null) canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, strokePaint);
    } else if (type == WhiteboardObjectType.circle) {
      final center = Offset(
        shapeData.position.dx + shapeData.size.width / 2,
        shapeData.position.dy + shapeData.size.height / 2,
      );
      final radius = (shapeData.size.width + shapeData.size.height) / 4;

      if (fillPaint != null) canvas.drawCircle(center, radius, fillPaint);
      canvas.drawCircle(center, radius, strokePaint);
    }
  }

  void _drawArrow(Canvas canvas, ShapeData shapeData) {
    final paint = Paint()
      ..color = Color(shapeData.strokeColor)
      ..strokeWidth = shapeData.strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final start = shapeData.position;
    final end = Offset(
      start.dx + shapeData.size.width,
      start.dy + shapeData.size.height,
    );

    // Draw line
    canvas.drawLine(start, end, paint);
    _drawArrowhead(canvas, start, end, paint);
  }

  void _drawArrowhead(Canvas canvas, Offset start, Offset end, Paint paint) {
    const arrowSize = 15.0;
    final angle = (end - start).direction;

    final arrowPath = Path();
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(
      end.dx - arrowSize * math.cos(angle - 0.5),
      end.dy - arrowSize * math.sin(angle - 0.5),
    );
    arrowPath.moveTo(end.dx, end.dy);
    arrowPath.lineTo(
      end.dx - arrowSize * math.cos(angle + 0.5),
      end.dy - arrowSize * math.sin(angle + 0.5),
    );

    canvas.drawPath(arrowPath, paint);
  }

  void _drawStickyNote(Canvas canvas, StickyNoteData noteData) {
    final rect = Rect.fromLTWH(
      noteData.position.dx,
      noteData.position.dy,
      noteData.size.width,
      noteData.size.height,
    );

    // Background
    final bgPaint = Paint()
      ..color = Color(noteData.color)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, borderPaint);

    // Text
    final textPainter = TextPainter(
      text: TextSpan(
        text: noteData.text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14.0,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    textPainter.layout(maxWidth: noteData.size.width - 16);
    textPainter.paint(
      canvas,
      Offset(noteData.position.dx + 8, noteData.position.dy + 8),
    );
  }

  void _drawTextBox(Canvas canvas, TextBoxData textData) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: textData.text,
        style: TextStyle(
          color: Color(textData.color),
          fontSize: textData.fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, textData.position);
  }

  void _drawTaskNode(Canvas canvas, TaskNode taskNode) {
    final rect = Rect.fromLTWH(
      taskNode.position.dx,
      taskNode.position.dy,
      200,
      120,
    );

    // Background
    final bgColor = _getTaskColor(taskNode.status);
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rrect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = _getTaskColor(taskNode.status).withOpacity(0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, borderPaint);

    // Priority indicator
    final priorityColor = _getPriorityColor(taskNode.priority);
    final priorityPaint = Paint()
      ..color = priorityColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(taskNode.position.dx + 16, taskNode.position.dy + 16),
      6,
      priorityPaint,
    );

    // Title
    final titlePainter = TextPainter(
      text: TextSpan(
        text: taskNode.title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    );
    titlePainter.layout(maxWidth: 160);
    titlePainter.paint(
      canvas,
      Offset(taskNode.position.dx + 12, taskNode.position.dy + 32),
    );

    // Description
    if (taskNode.description != null) {
      final descPainter = TextPainter(
        text: TextSpan(
          text: taskNode.description,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12.0,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 3,
        ellipsis: '...',
      );
      descPainter.layout(maxWidth: 176);
      descPainter.paint(
        canvas,
        Offset(taskNode.position.dx + 12, taskNode.position.dy + 60),
      );
    }

    // Status badge
    final statusText = taskNode.status.toUpperCase();
    final statusPainter = TextPainter(
      text: TextSpan(
        text: statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    statusPainter.layout();
    
    final badgeRect = Rect.fromLTWH(
      taskNode.position.dx + 12,
      taskNode.position.dy + 100,
      statusPainter.width + 12,
      20,
    );
    final badgePaint = Paint()
      ..color = _getStatusBadgeColor(taskNode.status)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(badgeRect, const Radius.circular(10)),
      badgePaint,
    );
    statusPainter.paint(
      canvas,
      Offset(taskNode.position.dx + 18, taskNode.position.dy + 105),
    );
  }

  Color _getTaskColor(String status) {
    switch (status) {
      case 'done':
        return Colors.green.withOpacity(0.1);
      case 'in_progress':
        return Colors.blue.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  Color _getStatusBadgeColor(String status) {
    switch (status) {
      case 'done':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  bool shouldRepaint(WhiteboardPainter oldDelegate) {
    return oldDelegate.objects != objects ||
        oldDelegate.taskNodes != taskNodes ||
        oldDelegate.zoom != zoom ||
        oldDelegate.pan != pan ||
        oldDelegate.currentPoints != currentPoints ||
        oldDelegate.startPoint != startPoint ||
        oldDelegate.endPoint != endPoint;
  }
}

extension OffsetExtension on Offset {
  double get direction => math.atan2(dy, dx);
}

