import 'package:flutter/material.dart';

class AuthCard extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const AuthCard({
    super.key,
    required this.child,
    this.maxWidth = 440,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 500;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 22 : 36,
            vertical: isCompact ? 28 : 36,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE9E5F2),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.07),
                blurRadius: 36,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
