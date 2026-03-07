import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import '../../models/app_enums.dart';
import '../theme/game_theme.dart';
import '../widgets/board_widget.dart';
import '../widgets/game_ui_components.dart';
import '../widgets/number_pad.dart';
import 'result_page.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  int _lastMessageVersion = -1;
  bool _navigatedToResult = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, _) {
        final palette = GameTheme.ui(context);
        final session = controller.session;
        final result = controller.lastResult;

        if (!_navigatedToResult && result != null && session == null) {
          _navigatedToResult = true;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ResultPage()),
            );
          });
        }

        if (controller.message != null &&
            controller.messageVersion != _lastMessageVersion) {
          _lastMessageVersion = controller.messageVersion;
          final message = controller.message!;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
            controller.clearMessage();
          });
        }

        if (session == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 68,
            leadingWidth: 58,
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
              child: GameCircleIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () {
                  final navigator = Navigator.of(context);
                  if (navigator.canPop()) {
                    navigator.pop();
                  }
                },
              ),
            ),
            titleSpacing: 10,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.kind == GameKind.daily
                      ? 'Daily Challenge'
                      : 'Quick Play',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: palette.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${session.puzzle.difficulty.label} • ${session.inputMode.label} mode',
                  style: TextStyle(
                    color: palette.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: GameCircleIconButton(
                    icon: Icons.tune_rounded,
                    onTap: () => _openSettings(context, controller),
                  ),
                ),
              ),
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              const _GameBackdrop(),
              LayoutBuilder(
                builder: (context, constraints) {
                  final media = MediaQuery.of(context);
                  final padding = media.padding;
                  final viewInsets = media.viewInsets;
                  final safeH = math.max(
                    0.0,
                    constraints.maxHeight -
                        padding.top -
                        math.max(padding.bottom, viewInsets.bottom),
                  );
                  final metrics = _GameLayoutMetrics.calculate(
                    safeHeight: safeH,
                    textScale: media.textScaler.scale(1.0),
                  );
                  return _GameContent(metrics: metrics);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GameBackdrop extends StatelessWidget {
  const _GameBackdrop();

  @override
  Widget build(BuildContext context) {
    final palette = GameTheme.ui(context);
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              palette.gameBackgroundTop,
              palette.gameBackgroundMid,
              palette.gameBackgroundBottom,
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -120,
              right: -120,
              child: _GlowBlob(
                size: 320,
                colors: [
                  palette.quickAccent.withValues(alpha: 0.32),
                  palette.quickAccent.withValues(alpha: 0),
                ],
              ),
            ),
            Positioned(
              top: 180,
              left: -90,
              child: _GlowBlob(
                size: 260,
                colors: [
                  palette.dailyAccent.withValues(alpha: 0.28),
                  palette.dailyAccent.withValues(alpha: 0),
                ],
              ),
            ),
            Positioned(
              bottom: -140,
              right: -40,
              child: _GlowBlob(
                size: 300,
                colors: [
                  palette.successAccent.withValues(alpha: 0.24),
                  palette.successAccent.withValues(alpha: 0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.size,
    required this.colors,
  });

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class _GameContent extends StatelessWidget {
  const _GameContent({
    required this.metrics,
  });

  final _GameLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: metrics.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: metrics.statsHeight,
              child: _HeaderStats(
                gap: metrics.statsGap,
                borderRadius: metrics.panelRadius,
                iconSize: metrics.statsIconSize,
                labelFontSize: metrics.statsLabelFontSize,
                valueFontSize: metrics.statsValueFontSize,
                chipPadding: metrics.statsChipPadding,
              ),
            ),
            SizedBox(height: metrics.spacing),
            const Expanded(child: BoardWidget()),
            SizedBox(height: metrics.spacing),
            SizedBox(
              height: metrics.keypadHeight,
              child: _AdaptiveKeypad(
                panelRadius: metrics.panelRadius,
                textScale: metrics.textScale,
              ),
            ),
            SizedBox(height: metrics.spacing),
            BottomActionBar(
              height: metrics.bottomBarHeight,
              borderRadius: metrics.panelRadius,
              padding: metrics.bottomBarPadding,
              gap: metrics.bottomBarGap,
              iconSize: metrics.bottomIconSize,
              fontSize: metrics.bottomFontSize,
            ),
          ],
        ),
      ),
    );
  }
}

class _AdaptiveKeypad extends StatelessWidget {
  const _AdaptiveKeypad({
    required this.panelRadius,
    required this.textScale,
  });

  final double panelRadius;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final keypadMetrics = _KeypadMetrics.calculate(
          maxHeight: constraints.maxHeight,
          textScale: textScale,
        );
        return NumberPad(
          buttonSize: keypadMetrics.buttonSize,
          fontSize: keypadMetrics.fontSize,
          padding: keypadMetrics.padding,
          spacing: keypadMetrics.spacing,
          borderRadius: panelRadius,
        );
      },
    );
  }
}

class _KeypadMetrics {
  const _KeypadMetrics({
    required this.buttonSize,
    required this.fontSize,
    required this.padding,
    required this.spacing,
  });

  final double buttonSize;
  final double fontSize;
  final double padding;
  final double spacing;

  static _KeypadMetrics calculate({
    required double maxHeight,
    required double textScale,
  }) {
    final compactT = ((168.0 - maxHeight) / 52.0).clamp(0.0, 1.0);
    final clampedScale = textScale.clamp(1.0, 1.35);
    final scaleT = clampedScale - 1.0;

    final padding = (9.0 - (compactT * 3.0) - (scaleT * 1.2)).clamp(5.0, 10.0);
    final spacing = (8.0 - (compactT * 2.3)).clamp(5.0, 8.0);
    final rawButtonHeight =
        (maxHeight - (padding * 2) - spacing).clamp(0.0, double.infinity) / 2;
    final buttonSize = rawButtonHeight.clamp(42.0, 68.0).toDouble();
    final fontSize =
        ((buttonSize * 0.36) / clampedScale).clamp(14.0, 24.0).toDouble();

    return _KeypadMetrics(
      buttonSize: buttonSize,
      fontSize: fontSize,
      padding: padding,
      spacing: spacing,
    );
  }
}

class _GameLayoutMetrics {
  const _GameLayoutMetrics({
    required this.pagePadding,
    required this.spacing,
    required this.panelRadius,
    required this.textScale,
    required this.statsHeight,
    required this.statsGap,
    required this.statsIconSize,
    required this.statsLabelFontSize,
    required this.statsValueFontSize,
    required this.statsChipPadding,
    required this.keypadHeight,
    required this.bottomBarHeight,
    required this.bottomBarPadding,
    required this.bottomBarGap,
    required this.bottomIconSize,
    required this.bottomFontSize,
  });

  final EdgeInsets pagePadding;
  final double spacing;
  final double panelRadius;
  final double textScale;
  final double statsHeight;
  final double statsGap;
  final double statsIconSize;
  final double statsLabelFontSize;
  final double statsValueFontSize;
  final EdgeInsets statsChipPadding;
  final double keypadHeight;
  final double bottomBarHeight;
  final double bottomBarPadding;
  final double bottomBarGap;
  final double bottomIconSize;
  final double bottomFontSize;

  static _GameLayoutMetrics calculate({
    required double safeHeight,
    required double textScale,
  }) {
    final compactT = ((760.0 - safeHeight) / 260.0).clamp(0.0, 1.0);
    final clampedScale = textScale.clamp(1.0, 1.35);
    final scaleT = clampedScale - 1.0;

    final horizontalInset = (16.0 - (compactT * 6.0)).clamp(10.0, 16.0);
    final pagePadding = EdgeInsets.fromLTRB(
      horizontalInset,
      6.0,
      horizontalInset,
      12.0,
    );
    final spacing = (13.0 - (compactT * 4.0)).clamp(8.0, 13.0);
    final panelRadius = (24.0 - (compactT * 4.0)).clamp(18.0, 24.0);

    final statsHeight = (82.0 + (scaleT * 10.0) - (compactT * 10.0))
        .clamp(70.0, 90.0)
        .floorToDouble();
    final bottomBarHeight = (84.0 + (scaleT * 8.0) - (compactT * 12.0))
        .clamp(68.0, 90.0)
        .floorToDouble();
    final keypadHeight = (154.0 + (scaleT * 12.0) - (compactT * 18.0))
        .clamp(122.0, 168.0)
        .floorToDouble();

    final statsGap = (10.0 - (compactT * 2.0)).clamp(6.0, 10.0).toDouble();
    final statsIconSize = ((16.0 - compactT) / clampedScale).clamp(13.0, 16.0);
    final statsLabelFontSize =
        ((11.0 - compactT) / clampedScale).clamp(9.0, 11.0);
    final statsValueFontSize =
        ((18.0 - (compactT * 1.4)) / clampedScale).clamp(13.0, 18.0);
    final statsChipPadding = EdgeInsets.symmetric(
      horizontal: (10.0 - compactT).clamp(8.0, 10.0),
      vertical: (7.0 - compactT).clamp(5.0, 7.0),
    );

    final bottomBarPadding = (7.0 - compactT).clamp(4.0, 7.0).toDouble();
    final bottomBarGap = (7.0 - compactT).clamp(4.0, 7.0).toDouble();
    final bottomIconSize =
        ((19.0 - (compactT * 1.2)) / clampedScale).clamp(15.0, 19.0);
    final bottomFontSize =
        ((12.0 - (compactT * 1.2)) / clampedScale).clamp(9.0, 12.0);

    return _GameLayoutMetrics(
      pagePadding: pagePadding,
      spacing: spacing,
      panelRadius: panelRadius,
      textScale: clampedScale,
      statsHeight: statsHeight,
      statsGap: statsGap,
      statsIconSize: statsIconSize,
      statsLabelFontSize: statsLabelFontSize,
      statsValueFontSize: statsValueFontSize,
      statsChipPadding: statsChipPadding,
      keypadHeight: keypadHeight,
      bottomBarHeight: bottomBarHeight,
      bottomBarPadding: bottomBarPadding,
      bottomBarGap: bottomBarGap,
      bottomIconSize: bottomIconSize,
      bottomFontSize: bottomFontSize,
    );
  }
}

class _HeaderStats extends StatelessWidget {
  const _HeaderStats({
    required this.gap,
    required this.borderRadius,
    required this.iconSize,
    required this.labelFontSize,
    required this.valueFontSize,
    required this.chipPadding,
  });

  final double gap;
  final double borderRadius;
  final double iconSize;
  final double labelFontSize;
  final double valueFontSize;
  final EdgeInsets chipPadding;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final palette = GameTheme.ui(context);
    final session = controller.session!;

    return Row(
      children: [
        Expanded(
          child: StatChip(
            label: 'Time',
            value: _formatSeconds(session.elapsedSeconds),
            icon: Icons.timer_rounded,
            tint: palette.quickAccent,
            iconSize: iconSize,
            labelFontSize: labelFontSize,
            valueFontSize: valueFontSize,
            borderRadius: borderRadius,
            padding: chipPadding,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: StatChip(
            label: 'Mistakes',
            value: '${session.mistakes}',
            icon: Icons.error_outline_rounded,
            tint: palette.dangerAccent,
            iconSize: iconSize,
            labelFontSize: labelFontSize,
            valueFontSize: valueFontSize,
            borderRadius: borderRadius,
            padding: chipPadding,
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: StatChip(
            label: 'Streak',
            value: '${controller.dailyProgress.streak}',
            icon: Icons.local_fire_department_rounded,
            tint: palette.hintAccent,
            iconSize: iconSize,
            labelFontSize: labelFontSize,
            valueFontSize: valueFontSize,
            borderRadius: borderRadius,
            padding: chipPadding,
          ),
        ),
      ],
    );
  }

  static String _formatSeconds(int total) {
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

void _openSettings(BuildContext context, GameController controller) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final palette = GameTheme.ui(context);
          final settings = context.watch<GameController>().settings;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sound'),
                  subtitle:
                      const Text('System tap/alert cues for input feedback.'),
                  value: settings.soundOn,
                  onChanged: controller.updateSound,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Haptic'),
                  subtitle: const Text('Light vibration for mistakes.'),
                  value: settings.hapticOn,
                  onChanged: controller.updateHaptic,
                ),
                const SizedBox(height: 10),
                Text(
                  'Error Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ErrorMode.values.map((mode) {
                    final isSelected = settings.errorMode == mode;
                    return ChoiceChip(
                      label: Text(
                        mode.label,
                        style: GameTheme.chipText(context).copyWith(
                          color: isSelected
                              ? palette.textPrimary
                              : palette.textMuted,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor:
                          palette.quickAccent.withValues(alpha: 0.26),
                      backgroundColor: Colors.white.withValues(alpha: 0.88),
                      checkmarkColor: palette.textPrimary,
                      side: BorderSide(
                        color: isSelected
                            ? palette.quickAccent.withValues(alpha: 0.62)
                            : palette.panelStroke,
                      ),
                      onSelected: (_) {
                        controller.updateErrorMode(mode);
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                Text(
                  settings.errorMode.description,
                  style: TextStyle(
                    color: palette.textMuted.withValues(alpha: 0.9),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
