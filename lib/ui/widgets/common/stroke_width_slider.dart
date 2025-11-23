import 'package:flutter/material.dart';

class StrokeWidthSlider extends StatelessWidget {
  final double value;
  final Function(double value) onChanged;
  final double min;
  final double max;
  final int divisions;

  const StrokeWidthSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1.0,
    this.max = 20.0,
    this.divisions = 19,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                label: '${value.toInt()}px',
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 48,
              alignment: Alignment.center,
              child: Text(
                '${value.toInt()}px',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        // Visual preview
        Center(
          child: Container(
            width: 100,
            height: value.clamp(1, 20),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(value / 2),
            ),
          ),
        ),
      ],
    );
  }
}
