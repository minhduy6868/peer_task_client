import 'package:flutter/material.dart';

/// Circular avatar: shows the user's photo when [imageUrl] is set and loads,
/// otherwise the initials of [name].
class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Color backgroundColor;
  final Color foregroundColor;
  final Gradient? gradient;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final int maxInitials;
  final double? fontSize;

  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 36,
    this.backgroundColor = const Color(0xFFEDE9FE),
    this.foregroundColor = const Color(0xFF6366F1),
    this.gradient,
    this.border,
    this.boxShadow,
    this.maxInitials = 2,
    this.fontSize,
  });

  static String initialsOf(String name, {int max = 2}) {
    final base = name.contains('@') ? name.split('@').first : name;
    final parts = base.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.map((p) => p[0].toUpperCase()).take(max).join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  Widget build(BuildContext context) {
    final initials = Center(
      child: Text(
        initialsOf(name, max: maxInitials),
        style: TextStyle(
          fontSize: fontSize ?? size * 0.38,
          fontWeight: FontWeight.w700,
          color: foregroundColor,
        ),
      ),
    );
    final url = imageUrl?.trim();
    final hasImage = url != null && url.startsWith('http');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        border: border,
        boxShadow: boxShadow,
      ),
      child: hasImage
          ? ClipOval(
              child: Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                cacheWidth: (size * 3).round(),
                errorBuilder: (_, __, ___) => initials,
              ),
            )
          : initials,
    );
  }
}
