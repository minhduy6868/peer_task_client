import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_button.dart';

/// Public homepage. Light product page: a slow color field, frosted bar,
/// and a floating board — the same kind of quiet motion large product sites use.
class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> with TickerProviderStateMixin {
  static const _contentWidth = 1120.0;

  late final AnimationController _enter;
  late final AnimationController _ambient;
  final _pointer = ValueNotifier<Offset?>(null);
  final _scrolled = ValueNotifier<bool>(false);
  final _taskKey = GlobalKey();
  final _canvasKey = GlobalKey();
  final _presenceKey = GlobalKey();
  var _motionReady = false;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _ambient = AnimationController(vsync: this, duration: const Duration(seconds: 22));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionReady) return;
    _motionReady = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
      return;
    }
    _enter.forward();
    _ambient.repeat();
  }

  @override
  void dispose() {
    _enter.dispose();
    _ambient.dispose();
    _pointer.dispose();
    _scrolled.dispose();
    super.dispose();
  }

  void _reveal(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    final reduce = MediaQuery.disableAnimationsOf(context);
    Scrollable.ensureVisible(
      target,
      duration: reduce ? Duration.zero : const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      alignment: 0.18,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 960;
    final pad = wide ? 48.0 : 20.0;
    final features = [
      (Icons.view_column_rounded, l10n.landingTasksTitle, l10n.landingTasksBody, _taskKey),
      (Icons.gesture_rounded, l10n.landingCanvasTitle, l10n.landingCanvasBody, _canvasKey),
      (Icons.record_voice_over_rounded, l10n.landingPresenceTitle, l10n.landingPresenceBody, _presenceKey),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: MouseRegion(
            onHover: (event) => _pointer.value = event.localPosition,
            onExit: (_) => _pointer.value = null,
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: _AmbientField(motion: _ambient, pointer: _pointer),
                  ),
                ),
                Column(
                  children: [
                    _nav(context, l10n, pad),
                    Expanded(child: _scroll(context, l10n, wide, pad, features)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scroll(
    BuildContext context,
    AppLocalizations l10n,
    bool wide,
    double pad,
    List<(IconData, String, String, GlobalKey)> features,
  ) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.axis != Axis.vertical) return false;
        final next = notification.metrics.pixels > 8;
        if (next != _scrolled.value) _scrolled.value = next;
        return false;
      },
      child: SingleChildScrollView(
        key: const Key('landing-scroll'),
        padding: EdgeInsets.only(top: wide ? 36 : 16, bottom: 36),
        child: _band(
          pad,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _hero(context, l10n, wide, features),
              SizedBox(height: wide ? 88 : 56),
              _rise(0.42, 1, _featureBlock(l10n, features)),
              SizedBox(height: wide ? 72 : 48),
              _rise(0.55, 1, _close(context, l10n)),
              const SizedBox(height: 28),
              _footer(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _band(double pad, Widget child) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: pad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _contentWidth),
          child: child,
        ),
      ),
    );
  }

  Widget _rise(double start, double end, Widget child) {
    return AnimatedBuilder(
      animation: _enter,
      child: child,
      builder: (context, child) {
        final span = end - start;
        final raw = span == 0 ? 1.0 : ((_enter.value - start) / span).clamp(0.0, 1.0);
        final t = Curves.easeOutCubic.transform(raw);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, (1 - t) * 18), child: child),
        );
      },
    );
  }

  Widget _nav(BuildContext context, AppLocalizations l10n, double pad) {
    return AnimatedBuilder(
      animation: _scrolled,
      builder: (context, _) {
        final lifted = _scrolled.value;
        return ClipRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: lifted ? 0.92 : 0.72),
                border: Border(bottom: BorderSide(color: lifted ? AppColors.border : AppColors.borderLight)),
                boxShadow: lifted
                    ? [BoxShadow(color: AppColors.shadowLight, blurRadius: 18, offset: const Offset(0, 6))]
                    : const [],
              ),
              child: _band(
                pad,
                SizedBox(
                  height: 64,
                  child: Row(
                    children: [
                      const _LogoMark(),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          l10n.appTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppButton(
                                  label: l10n.signIn,
                                  variant: ButtonVariant.text,
                                  size: ButtonSize.small,
                                  onPressed: () => context.go('/login'),
                                ),
                                const SizedBox(width: 4),
                                AppButton(
                                  label: l10n.getStarted,
                                  size: ButtonSize.small,
                                  color: AppColors.primaryDark,
                                  onPressed: () => context.go('/login'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _hero(
    BuildContext context,
    AppLocalizations l10n,
    bool wide,
    List<(IconData, String, String, GlobalKey)> features,
  ) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _rise(0, 0.45, _eyebrow(l10n)),
        const SizedBox(height: 16),
        _rise(0.08, 0.62, _headline(l10n, wide)),
        const SizedBox(height: 16),
        _rise(
          0.16,
          0.7,
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(
              l10n.landingSubhead,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary, height: 1.55, letterSpacing: 0),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _rise(0.24, 0.78, _actions(context, l10n)),
        const SizedBox(height: 18),
        _rise(0.32, 0.86, _anchors(features)),
      ],
    );

    final preview = _rise(0.18, 0.9, _BoardPreview(motion: _ambient, l10n: l10n));
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [copy, const SizedBox(height: 32), preview],
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

  Widget _eyebrow(AppLocalizations l10n) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LiveDot(motion: _ambient),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n.realTimeCollaboration,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headline(AppLocalizations l10n, bool wide) {
    return Text(
      l10n.landingHeadline,
      style: AppTextStyles.displayMedium.copyWith(
        fontSize: wide ? 56 : 34,
        height: 1.12,
        letterSpacing: wide ? -1.2 : -0.6,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _actions(BuildContext context, AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 480;
        final start = _glow(
          AppButton(
            label: l10n.getStarted,
            size: ButtonSize.medium,
            color: AppColors.primaryDark,
            isFullWidth: stack,
            onPressed: () => context.go('/login'),
          ),
        );
        final offline = AppButton(
          label: l10n.continueOffline,
          variant: ButtonVariant.outlined,
          size: ButtonSize.medium,
          isFullWidth: stack,
          onPressed: () => context.go('/offline-username'),
        );
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [start, const SizedBox(height: 8), offline],
          );
        }
        return Wrap(spacing: 8, runSpacing: 8, children: [start, offline]);
      },
    );
  }

  Widget _glow(Widget child) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppColors.createPrimaryShadow(opacity: 0.28, blurRadius: 18, offset: const Offset(0, 8)),
      ),
      child: child,
    );
  }

  Widget _anchors(List<(IconData, String, String, GlobalKey)> features) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < features.length; i++)
          _AnchorChip(
            key: Key('landing-chip-$i'),
            label: features[i].$2,
            onTap: () => _reveal(features[i].$4),
          ),
      ],
    );
  }

  Widget _featureBlock(AppLocalizations l10n, List<(IconData, String, String, GlobalKey)> features) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.landingFeaturesHeading,
          style: AppTextStyles.headlineSmall.copyWith(letterSpacing: -0.4, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              for (final feature in features)
                _FeatureCard(
                  key: feature.$4,
                  icon: feature.$1,
                  title: feature.$2,
                  body: feature.$3,
                ),
            ];
            if (constraints.maxWidth < 860) {
              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    cards[i],
                  ],
                ],
              );
            }
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: cards[i]),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _close(BuildContext context, AppLocalizations l10n) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.gradientSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -48,
              child: IgnorePointer(
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [AppColors.primaryLight.withValues(alpha: 0.7), AppColors.primaryLight.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Text(
                    l10n.landingCta,
                    style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
                  ),
                  _glow(
                    AppButton(
                      label: l10n.getStarted,
                      color: AppColors.primaryDark,
                      onPressed: () => context.go('/login'),
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

  Widget _footer(AppLocalizations l10n) {
    return Column(
      children: [
        const Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(l10n.appTitle, style: AppTextStyles.titleSmall.copyWith(color: AppColors.textSecondary)),
              Text(
                l10n.realTimeCollaboration,
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: AppColors.gradientElegant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.dashboard_customize_rounded, color: AppColors.textOnPrimary, size: 16),
    );
  }
}

class _AmbientField extends StatelessWidget {
  const _AmbientField({required this.motion, required this.pointer});

  final Animation<double> motion;
  final ValueListenable<Offset?> pointer;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: Listenable.merge([motion, pointer]),
            builder: (context, _) {
              final t = motion.value * math.pi * 2;
              final spot = pointer.value;
              return Stack(
                children: [
                  _orb(Alignment(-0.72 + 0.08 * math.sin(t), -0.78 + 0.05 * math.cos(t)), 560, AppColors.primaryLight, 0.62, t),
                  _orb(Alignment(0.86 + 0.06 * math.cos(t * 0.8), -0.42 + 0.07 * math.sin(t * 0.7)), 480, AppColors.secondaryLight, 0.7, t + 2),
                  _orb(Alignment(0.28 + 0.05 * math.sin(t * 0.6), -0.05), 340, AppColors.accent, 0.16, t + 4),
                  if (spot != null)
                    Positioned(
                      left: spot.dx - 190,
                      top: spot.dy - 190,
                      child: Container(
                        width: 380,
                        height: 380,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [AppColors.primary.withValues(alpha: 0.16), AppColors.primary.withValues(alpha: 0)],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _orb(Alignment alignment, double size, Color color, double strength, double phase) {
    final breathe = 0.78 + 0.22 * ((math.sin(phase) + 1) / 2);
    return Align(
      alignment: alignment,
      child: Opacity(
        opacity: breathe,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color.withValues(alpha: strength), color.withValues(alpha: 0)],
            ),
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.textTertiary.withValues(alpha: 0.28);
    const gap = 24.0;
    for (var y = 0.0; y < size.height; y += gap) {
      for (var x = 0.0; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 0.7, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) => false;
}

class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.motion});

  final Animation<double> motion;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: motion,
      builder: (context, _) {
        final t = _phase(motion.value, 14);
        return SizedBox(
          width: 14,
          height: 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 7 + 7 * t,
                height: 7 + 7 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.online.withValues(alpha: 0.38 * (1 - t)),
                ),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(color: AppColors.online, shape: BoxShape.circle),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnchorChip extends StatelessWidget {
  const _AnchorChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({super.key, required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final shadow = _hover
        ? AppColors.elegantCardShadow
        : [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0), blurRadius: 20, offset: const Offset(0, 4)),
            BoxShadow(color: AppColors.primary.withValues(alpha: 0), blurRadius: 10, offset: const Offset(0, 2)),
          ];
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        transformAlignment: Alignment.center,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _hover ? AppColors.primaryLight : AppColors.border),
          boxShadow: shadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.icon, size: 18, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 14),
            Text(widget.title, style: AppTextStyles.titleMedium.copyWith(letterSpacing: -0.2)),
            const SizedBox(height: 6),
            Text(
              widget.body,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5, letterSpacing: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardPreview extends StatelessWidget {
  const _BoardPreview({required this.motion, required this.l10n});

  final Animation<double> motion;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: motion,
      builder: (context, child) {
        final dy = math.sin(motion.value * math.pi * 2 * 5) * 7;
        final sheen = _phase(motion.value, 5);
        return Transform.translate(
          offset: Offset(0, dy),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                ...AppColors.elegantCardShadow,
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.14), blurRadius: 42, offset: const Offset(0, 22)),
              ],
            ),
            child: Stack(
              children: [
                child!,
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(-1.35 + sheen * 2.8, -0.8),
                          end: Alignment(-0.75 + sheen * 2.8, 0.8),
                          colors: [
                            AppColors.surface.withValues(alpha: 0),
                            AppColors.textOnPrimary.withValues(alpha: 0.42),
                            AppColors.surface.withValues(alpha: 0),
                          ],
                          stops: const [0.38, 0.5, 0.62],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _WindowDots(),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.landingPreviewCaption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lane(l10n.todo, [l10n.landingPreviewKickoff, l10n.landingPreviewInvite]),
                const SizedBox(width: 8),
                _lane(l10n.doing, [l10n.landingPreviewLayout]),
                const SizedBox(width: 8),
                _lane(l10n.done, [l10n.landingPreviewVoice]),
              ],
            ),
            const SizedBox(height: 10),
            _canvasStrip(),
            const SizedBox(height: 10),
            _people(),
          ],
        ),
      ),
    );
  }

  Widget _lane(String title, List<String> cards) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              for (final card in cards)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    card,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, letterSpacing: 0),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _canvasStrip() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: SizedBox(
        height: 72,
        child: Row(
          children: [
            const SizedBox(width: 12),
            SizedBox(
              width: 88,
              child: Text(
                l10n.landingCanvasTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
            const Expanded(child: CustomPaint(painter: _SketchPainter())),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _people() {
    return Row(
      children: [
        const SizedBox(
          width: 62,
          height: 28,
          child: Stack(
            children: [
              Positioned(left: 0, child: _Person(color: AppColors.primary, icon: Icons.person_rounded)),
              Positioned(left: 16, child: _Person(color: AppColors.secondaryDark, icon: Icons.person_rounded)),
              Positioned(left: 32, child: _Person(color: AppColors.primaryDark, icon: Icons.mic_rounded)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            l10n.speaking,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _WindowDots extends StatelessWidget {
  const _WindowDots();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _Dot(AppColors.primaryLight),
        SizedBox(width: 4),
        _Dot(AppColors.secondary),
        SizedBox(width: 4),
        _Dot(AppColors.accent),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

class _Person extends StatelessWidget {
  const _Person({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
      ),
      child: Icon(icon, size: 14, color: AppColors.textOnPrimary),
    );
  }
}

class _SketchPainter extends CustomPainter {
  const _SketchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.primaryDark;
    final path = Path()
      ..moveTo(size.width * 0.04, size.height * 0.68)
      ..cubicTo(size.width * 0.18, size.height * 0.12, size.width * 0.3, size.height * 0.9, size.width * 0.48, size.height * 0.4)
      ..cubicTo(size.width * 0.64, size.height * 0.02, size.width * 0.76, size.height * 0.8, size.width * 0.96, size.height * 0.28);
    canvas.drawPath(path, pen);

    final note = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = AppColors.accent;
    canvas.drawLine(Offset(size.width * 0.1, size.height * 0.8), Offset(size.width * 0.36, size.height * 0.8), note);
  }

  @override
  bool shouldRepaint(covariant _SketchPainter oldDelegate) => false;
}

double _phase(double t, double cycles) {
  final value = t * cycles;
  return value - value.floorToDouble();
}
