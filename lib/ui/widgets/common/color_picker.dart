import 'package:flutter/material.dart';

class ColorPicker extends StatelessWidget {
  final int selectedColor;
  final Function(int color) onColorSelected;
  final List<Color> colors;

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.colors = const [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.brown,
      Colors.teal,
      Colors.cyan,
      Colors.grey,
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        final isSelected = selectedColor == color.value;
        return GestureDetector(
          onTap: () => onColorSelected(color.value),
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
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
