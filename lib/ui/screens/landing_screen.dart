import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _motion,
                builder: (context, child) {
                  final t = _motion.value * math.pi * 2;
                  return Stack(
                    children: [
                      _orb(const Alignment(-1.1, -0.8), 280, AppColors.primaryLight, math.sin(t) * 18),
                      _orb(const Alignment(1.15, -0.2), 340, AppColors.accent, math.cos(t) * 22),
                      _orb(const Alignment(-0.4, 1.2), 260, AppColors.secondaryLight, math.sin(t + 1) * 16),
                    ],
                  );
                },
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _nav(context, l10n, wide)),
                SliverToBoxAdapter(child: _hero(context, l10n, wide)),
                SliverToBoxAdapter(child: _features(l10n, wide)),
                SliverToBoxAdapter(child: _close(context, l10n)),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _orb(Alignment alignment, double size, Color color, double drift) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(drift, drift * 0.6),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withOpacity(0.45), color.withOpacity(0)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nav(BuildContext context, AppLocalizations l10n, bool wide) {
    return Padding(
      padding: EdgeInsets.fromLTRB(wide ? 48 : 20, 12, wide ? 48 : 20, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            l10n.appTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text(l10n.signIn),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => context.go('/login'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: Text(l10n.getStarted),
          ),
        ],
      ),
    );
  }

  Widget _hero(BuildContext context, AppLocalizations l10n, bool wide) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primarySubtle,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            l10n.realTimeCollaboration,
            style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.landingHeadline,
          style: TextStyle(
            fontSize: wide ? 56 : 36,
            height: 1.05,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            l10n.landingSubhead,
            style: const TextStyle(fontSize: 18, height: 1.45, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              onPressed: () => context.go('/login'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              ),
              child: Text(l10n.getStarted),
            ),
            OutlinedButton(
              onPressed: () => context.go('/offline-username'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                side: const BorderSide(color: AppColors.primaryLight),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              ),
              child: Text(l10n.continueOffline),
            ),
          ],
        ),
      ],
    );

    final preview = AnimatedBuilder(
      animation: _motion,
      builder: (context, child) {
        final lift = math.sin(_motion.value * math.pi * 2) * 8;
        return Transform.translate(offset: Offset(0, lift), child: child);
      },
      child: const _BoardPreview(),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(wide ? 48 : 20, wide ? 48 : 28, wide ? 48 : 20, 24),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: copy),
                const SizedBox(width: 40),
                Expanded(child: preview),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: 28),
                preview,
              ],
            ),
    );
  }

  Widget _features(AppLocalizations l10n, bool wide) {
    final items = [
      (Icons.view_column_rounded, l10n.landingTasksTitle, l10n.landingTasksBody),
      (Icons.draw_rounded, l10n.landingCanvasTitle, l10n.landingCanvasBody),
      (Icons.record_voice_over_rounded, l10n.landingPresenceTitle, l10n.landingPresenceBody),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(wide ? 48 : 20, 12, wide ? 48 : 20, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 800 ? 3 : 1;
          final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final item in items)
                SizedBox(
                  width: width,
                  child: _FeatureCard(icon: item.$1, title: item.$2, body: item.$3),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _close(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            decoration: BoxDecoration(
              gradient: AppColors.gradientElegant,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  l10n.landingCta,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/login'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  ),
                  child: Text(l10n.getStarted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _FeatureCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 14),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}

class _BoardPreview extends StatelessWidget {
  const _BoardPreview();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
        boxShadow: AppColors.elegantCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.landingPreviewCaption, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              _column(l10n.todo, const ['Kickoff', 'Invite']),
              const SizedBox(width: 8),
              _column(l10n.doing, const ['Layout']),
              const SizedBox(width: 8),
              _column(l10n.done, const ['Voice']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _column(String title, List<String> cards) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primarySubtle,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            const SizedBox(height: 8),
            for (final card in cards) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(card, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
