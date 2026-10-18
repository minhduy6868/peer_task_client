import 'package:flutter/material.dart';
import '../app_language_switcher.dart';

class AuthLayout extends StatelessWidget {
  final Widget child;

  const AuthLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 500;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5FF),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Ambient Decorative Gradients (Matching Landing Page & SaaS Theme)
            const Positioned.fill(
              child: IgnorePointer(
                child: _AuthAmbientBackground(),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, isCompact ? 10 : 16, 16, 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFE9E5F2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const AppLanguageSwitcher(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 16 : 24,
                          vertical: isCompact ? 16 : 32,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthAmbientBackground extends StatelessWidget {
  const _AuthAmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-left soft violet glow
        Positioned(
          top: -120,
          left: -100,
          child: Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFA78BFA).withValues(alpha: 0.35),
                  const Color(0xFFA78BFA).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // Bottom-right soft purple glow
        Positioned(
          bottom: -140,
          right: -120,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFC4B5FD).withValues(alpha: 0.40),
                  const Color(0xFFC4B5FD).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),

        // Center-left subtle accent
        Positioned(
          top: 240,
          left: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFDDD6FE).withValues(alpha: 0.30),
                  const Color(0xFFDDD6FE).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
