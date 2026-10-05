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
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wide = MediaQuery.sizeOf(context).width >= 960;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _nav(context, l10n),
          Expanded(
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _enter, curve: Curves.easeOut),
              child: ListView(
                padding: EdgeInsets.fromLTRB(wide ? 48 : 20, 28, wide ? 48 : 20, 48),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _hero(context, l10n, wide),
                          const SizedBox(height: 56),
                          _features(l10n, wide),
                          const SizedBox(height: 56),
                          _close(context, l10n),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nav(BuildContext context, AppLocalizations l10n) {
    return Material(
      color: AppColors.surface,
      child: Container(
        height: 64,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(l10n.appTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const Spacer(),
            TextButton(onPressed: () => context.go('/login'), child: Text(l10n.signIn)),
            const SizedBox(width: 8),
            FilledButton(onPressed: () => context.go('/login'), child: Text(l10n.getStarted)),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, AppLocalizations l10n, bool wide) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.realTimeCollaboration,
          style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.landingHeadline,
          style: TextStyle(
            fontSize: wide ? 52 : 34,
            height: 1.05,
            letterSpacing: -1.2,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Text(
            l10n.landingSubhead,
            style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(onPressed: () => context.go('/login'), child: Text(l10n.getStarted)),
            OutlinedButton(onPressed: () => context.go('/offline-username'), child: Text(l10n.continueOffline)),
          ],
        ),
      ],
    );

    final preview = const _BoardPreview();
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [copy, const SizedBox(height: 28), preview],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 5, child: copy),
        const SizedBox(width: 48),
        Expanded(flex: 6, child: preview),
      ],
    );
  }

  Widget _features(AppLocalizations l10n, bool wide) {
    final items = [
      (l10n.landingTasksTitle, l10n.landingTasksBody),
      (l10n.landingCanvasTitle, l10n.landingCanvasBody),
      (l10n.landingPresenceTitle, l10n.landingPresenceBody),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 800 ? 3 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(item.$2, style: const TextStyle(color: AppColors.textSecondary, height: 1.45)),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _close(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          Text(
            l10n.landingCta,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4),
          ),
          FilledButton(onPressed: () => context.go('/login'), child: Text(l10n.getStarted)),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.landingPreviewCaption, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (final card in cards)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(card, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}
