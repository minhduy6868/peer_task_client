import 'package:flutter/material.dart';

enum DrawingTool {
  select,
  pen,
  eraser,
  rectangle,
  circle,
  line,
  arrow,
  text,
  taskNode,
  stickyNote,
}

class DrawingToolbar extends StatelessWidget {
  final DrawingTool selectedTool;
  final Color selectedColor;
  final double strokeWidth;
  final Function(DrawingTool) onToolSelected;
  final Function(Color) onColorSelected;
  final Function(double) onStrokeWidthChanged;
  final VoidCallback onClear;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  const DrawingToolbar({
    super.key,
    required this.selectedTool,
    required this.selectedColor,
    required this.strokeWidth,
    required this.onToolSelected,
    required this.onColorSelected,
    required this.onStrokeWidthChanged,
    required this.onClear,
    required this.onUndo,
    required this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main tools
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              alignment: WrapAlignment.center,
              children: [
                _ToolButton(
                  icon: Icons.near_me,
                  label: 'Select',
                  isSelected: selectedTool == DrawingTool.select,
                  onTap: () => onToolSelected(DrawingTool.select),
                ),
                _ToolButton(
                  icon: Icons.edit,
                  label: 'Pen',
                  isSelected: selectedTool == DrawingTool.pen,
                  onTap: () => onToolSelected(DrawingTool.pen),
                ),
                _ToolButton(
                  icon: Icons.auto_fix_high,
                  label: 'Eraser',
                  isSelected: selectedTool == DrawingTool.eraser,
                  onTap: () => onToolSelected(DrawingTool.eraser),
                ),
                _ToolButton(
                  icon: Icons.crop_square,
                  label: 'Rectangle',
                  isSelected: selectedTool == DrawingTool.rectangle,
                  onTap: () => onToolSelected(DrawingTool.rectangle),
                ),
                _ToolButton(
                  icon: Icons.circle_outlined,
                  label: 'Circle',
                  isSelected: selectedTool == DrawingTool.circle,
                  onTap: () => onToolSelected(DrawingTool.circle),
                ),
                _ToolButton(
                  icon: Icons.show_chart,
                  label: 'Line',
                  isSelected: selectedTool == DrawingTool.line,
                  onTap: () => onToolSelected(DrawingTool.line),
                ),
                _ToolButton(
                  icon: Icons.arrow_forward,
                  label: 'Arrow',
                  isSelected: selectedTool == DrawingTool.arrow,
                  onTap: () => onToolSelected(DrawingTool.arrow),
                ),
                _ToolButton(
                  icon: Icons.text_fields,
                  label: 'Text',
                  isSelected: selectedTool == DrawingTool.text,
                  onTap: () => onToolSelected(DrawingTool.text),
                ),
                _ToolButton(
                  icon: Icons.sticky_note_2,
                  label: 'Note',
                  isSelected: selectedTool == DrawingTool.stickyNote,
                  onTap: () => onToolSelected(DrawingTool.stickyNote),
                ),
                _ToolButton(
                  icon: Icons.task,
                  label: 'Task',
                  isSelected: selectedTool == DrawingTool.taskNode,
                  onTap: () => onToolSelected(DrawingTool.taskNode),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Color picker
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Colors.black,
                    Colors.white,
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue,
                    Colors.indigo,
                    Colors.purple,
                    Colors.pink,
                    Colors.brown,
                    Colors.grey,
                  ].map((color) => _ColorButton(
                    color: color,
                    isSelected: selectedColor == color,
                    onTap: () => onColorSelected(color),
                  )).toList(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Stroke width
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Stroke Width', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${strokeWidth.toInt()}px', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                Slider(
                  value: strokeWidth,
                  min: 1,
                  max: 20,
                  divisions: 19,
                  onChanged: onStrokeWidthChanged,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Actions
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: onUndo,
                  tooltip: 'Undo',
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  onPressed: onRedo,
                  tooltip: 'Redo',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onClear,
                  tooltip: 'Clear All',
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 60,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey[700]),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? Colors.blue : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorButton extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ] : null,
        ),
      ),
    );
  }
}
