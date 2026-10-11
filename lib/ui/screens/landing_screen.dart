import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/apk_download.dart';
import '../../utils/error_display.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_button.dart';

/// Public homepage: stunning light product page with ambient color field,
/// frosted navigation bar, and an interactive studio board mockup.
class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> with TickerProviderStateMixin {
  static const _contentWidth = 1140.0;

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

  Future<void> _downloadApk() async {
    final opened = await launchAndroidApkDownload();
    if (!opened && mounted) {
      context.showErrorSnackBar(AppLocalizations.of(context)!.downloadAndroidAppFailed);
    }
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
      (Icons.view_column_rounded, l10n.landingTasksTitle, l10n.landingTasksBody, _taskKey, '01'),
      (Icons.draw_rounded, l10n.landingCanvasTitle, l10n.landingCanvasBody, _canvasKey, '02'),
      (Icons.record_voice_over_rounded, l10n.landingPresenceTitle, l10n.landingPresenceBody, _presenceKey, '03'),
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
    List<(IconData, String, String, GlobalKey, String)> features,
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
        padding: EdgeInsets.only(top: wide ? 36 : 16, bottom: 48),
        child: _band(
          pad,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _hero(context, l10n, wide, features),
              SizedBox(height: wide ? 96 : 64),
              _rise(0.42, 1, _featureBlock(l10n, features)),
              SizedBox(height: wide ? 80 : 56),
              _rise(0.55, 1, _close(context, l10n)),
              const SizedBox(height: 36),
              _footer(context, l10n),
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
                color: AppColors.surface.withValues(alpha: lifted ? 0.94 : 0.78),
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
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: AppColors.textPrimary,
                          ),
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
    List<(IconData, String, String, GlobalKey, String)> features,
  ) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _rise(0, 0.45, _eyebrow(l10n)),
        const SizedBox(height: 18),
        _rise(0.08, 0.62, _headline(l10n, wide)),
        const SizedBox(height: 18),
        _rise(
          0.16,
          0.7,
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              l10n.landingSubhead,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
                letterSpacing: 0,
                fontSize: wide ? 17 : 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        _rise(0.24, 0.78, _actions(context, l10n)),
        const SizedBox(height: 20),
        _rise(0.32, 0.86, _anchors(features)),
      ],
    );

    final preview = _rise(0.18, 0.9, _BoardPreview(motion: _ambient, l10n: l10n));
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [copy, const SizedBox(height: 36), preview],
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LiveDot(motion: _ambient),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l10n.realTimeCollaboration,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
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
        fontSize: wide ? 52 : 32,
        height: 1.15,
        letterSpacing: wide ? -1.4 : -0.6,
        fontWeight: FontWeight.w800,
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
        final download = kIsWeb
            ? AppButton(
                label: l10n.downloadAndroidApp,
                icon: Icons.android_rounded,
                variant: ButtonVariant.outlined,
                size: ButtonSize.medium,
                color: AppColors.primaryDark,
                isFullWidth: stack,
                onPressed: _downloadApk,
              )
            : null;
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              start,
              const SizedBox(height: 10),
              offline,
              if (download != null) ...[const SizedBox(height: 10), download],
            ],
          );
        }
        return Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [start, offline, if (download != null) download],
        );
      },
    );
  }

  Widget _glow(Widget child) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppColors.createPrimaryShadow(opacity: 0.32, blurRadius: 20, offset: const Offset(0, 6)),
      ),
      child: child,
    );
  }

  Widget _anchors(List<(IconData, String, String, GlobalKey, String)> features) {
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

  Widget _featureBlock(AppLocalizations l10n, List<(IconData, String, String, GlobalKey, String)> features) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'FEATURES',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.landingFeaturesHeading,
          style: AppTextStyles.headlineSmall.copyWith(
            letterSpacing: -0.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final cards = [
              for (final feature in features)
                _FeatureCard(
                  key: feature.$4,
                  index: feature.$5,
                  icon: feature.$1,
                  title: feature.$2,
                  body: feature.$3,
                ),
            ];
            if (constraints.maxWidth < 860) {
              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
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
                    if (i > 0) const SizedBox(width: 16),
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
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.gradientPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -40,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.25),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 20,
                runSpacing: 16,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.landingCta,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.collaborativeDescription.split('\n').first,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => context.go('/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          l10n.getStarted,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                      if (kIsWeb)
                        OutlinedButton.icon(
                          onPressed: _downloadApk,
                          icon: const Icon(Icons.android_rounded, size: 18),
                          label: Text(
                            l10n.downloadAndroidApp,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer(BuildContext context, AppLocalizations l10n) {
    final brand = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _LogoMark(),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.appTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l10n.realTimeCollaboration,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (kIsWeb)
          AppButton(
            label: l10n.downloadAndroidApp,
            icon: Icons.android_rounded,
            variant: ButtonVariant.outlined,
            size: ButtonSize.small,
            color: AppColors.primaryDark,
            onPressed: _downloadApk,
          ),
        AppButton(
          label: l10n.signIn,
          variant: ButtonVariant.text,
          size: ButtonSize.small,
          onPressed: () => context.go('/login'),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1, color: AppColors.divider),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  brand,
                  const SizedBox(height: 14),
                  actions,
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: brand),
                const SizedBox(width: 16),
                actions,
              ],
            );
          },
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
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.dashboard_customize_rounded, color: Colors.white, size: 16),
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
                  _orb(Alignment(-0.72 + 0.08 * math.sin(t), -0.78 + 0.05 * math.cos(t)), 580, AppColors.primaryLight, 0.58, t),
                  _orb(Alignment(0.86 + 0.06 * math.cos(t * 0.8), -0.42 + 0.07 * math.sin(t * 0.7)), 500, AppColors.secondaryLight, 0.65, t + 2),
                  _orb(Alignment(0.28 + 0.05 * math.sin(t * 0.6), -0.05), 360, AppColors.accent, 0.18, t + 4),
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
    final paint = Paint()..color = AppColors.textTertiary.withValues(alpha: 0.22);
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
                  color: AppColors.online.withValues(alpha: 0.45 * (1 - t)),
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
      color: AppColors.surface.withValues(alpha: 0.95),
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
  const _FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.index,
  });

  final IconData icon;
  final String title;
  final String body;
  final String index;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final shadow = _hover
        ? AppColors.hoverShadow
        : [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 4)),
          ];

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hover ? AppColors.primary : AppColors.borderLight,
            width: _hover ? 1.5 : 1,
          ),
          boxShadow: shadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPrimary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, size: 22, color: Colors.white),
                ),
                Text(
                  widget.index,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryLight.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              widget.title,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.body,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.55,
                letterSpacing: 0,
              ),
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
        final dy = math.sin(motion.value * math.pi * 2 * 5) * 6;
        final sheen = _phase(motion.value, 5);
        return Transform.translate(
          offset: Offset(0, dy),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                ...AppColors.elegantCardShadow,
                BoxShadow(color: AppColors.primary.withValues(alpha: 0.16), blurRadius: 40, offset: const Offset(0, 20)),
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
                            Colors.white.withValues(alpha: 0.38),
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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Window Header Bar
            Row(
              children: [
                const _WindowDots(),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.landingPreviewCaption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Kanban columns
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lane(l10n.todo, [l10n.landingPreviewKickoff, l10n.landingPreviewInvite], const Color(0xFF8B7CFF)),
                const SizedBox(width: 8),
                _lane(l10n.doing, [l10n.landingPreviewLayout], const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _lane(l10n.done, [l10n.landingPreviewVoice], const Color(0xFF10B981)),
              ],
            ),
            const SizedBox(height: 10),
            // Canvas Strip
            _canvasStrip(),
            const SizedBox(height: 10),
            // Collaborator Bar
            _people(),
          ],
        ),
      ),
    );
  }

  Widget _lane(String title, List<String> cards, Color accent) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        padding: const EdgeInsets.all(7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final card in cards)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  card,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _canvasStrip() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      height: 72,
      child: Row(
        children: [
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              l10n.landingCanvasTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
            ),
          ),
          const Expanded(child: CustomPaint(painter: _SketchPainter())),
          const SizedBox(width: 8),
        ],
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
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
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
        _Dot(Color(0xFFEF4444)),
        SizedBox(width: 6),
        _Dot(Color(0xFFF59E0B)),
        SizedBox(width: 6),
        _Dot(Color(0xFF10B981)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
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
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
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
      ..strokeWidth = 2.4
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
      ..strokeWidth = 1.8
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
