import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import '../../models/app_enums.dart';
import '../../models/game_session.dart';
import '../theme/game_theme.dart';
import 'daily_calendar_page.dart';
import 'game_page.dart';
import 'shop_page.dart';
import 'stats_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  PuzzleDifficulty _quickDifficulty = PuzzleDifficulty.medium;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    if (const bool.fromEnvironment('FLUTTER_TEST')) {
      _pulseController.value = 0.45;
    } else {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, _) {
        final todayKey = _todayKey();
        final dailyDone = controller.dailyProgress.isCompleted(todayKey);
        final hasActiveSession =
            controller.hasActiveSession && controller.session != null;
        final session = controller.session;
        final activeDaily = hasActiveSession && session!.isDaily;

        return Scaffold(
          body: Stack(
            children: [
              const Positioned.fill(child: _GameMenuBackground()),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HomeTopHeader(
                            coins: controller.coins,
                            onInfoTap: () => _openInfoSheet(context, controller),
                            onShopTap: () => _openShop(context),
                          ),
                          const SizedBox(height: 20),
                          _DailyHeroCard(
                            pulse: _pulseController,
                            streak: controller.dailyProgress.streak,
                            dailyDone: dailyDone,
                            hapticEnabled: controller.settings.hapticOn,
                            actionLabel: activeDaily
                                ? 'Continue Daily Board'
                                : (dailyDone
                                    ? 'Replay Daily Board'
                                    : 'Play Daily Board'),
                            onPressed: () {
                              if (activeDaily) {
                                _openGame(context);
                                return;
                              }
                              controller.startDailyChallenge();
                              _openGame(context);
                            },
                          ),
                          const SizedBox(height: 16),
                          _QuickRunCard(
                            selected: _quickDifficulty,
                            hapticEnabled: controller.settings.hapticOn,
                            onDifficultySelected: (difficulty) {
                              setState(() {
                                _quickDifficulty = difficulty;
                              });
                            },
                            onStart: () {
                              controller.startQuickGame(_quickDifficulty);
                              _openGame(context);
                            },
                          ),
                          const SizedBox(height: 16),
                          if (hasActiveSession && session != null) ...[
                            _ContinueLastGameCard(
                              session: session,
                              elapsedLabel: _formatDuration(
                                session.elapsedSeconds,
                              ),
                              hapticEnabled: controller.settings.hapticOn,
                              onResume: () => _openGame(context),
                            ),
                            const SizedBox(height: 16),
                          ],
                          _ProgressHubCard(
                            totalGames: controller.playerStats.totalGames,
                            completedDays:
                                controller.dailyProgress.completedDates.length,
                            hapticEnabled: controller.settings.hapticOn,
                            onOpenStats: () => _openStats(context),
                            onOpenCalendar: () => _openDailyCalendar(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openGame(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GamePage()),
    );
  }

  void _openShop(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ShopPage()),
    );
  }

  void _openStats(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StatsPage()),
    );
  }

  void _openDailyCalendar(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DailyCalendarPage()),
    );
  }

  void _openInfoSheet(BuildContext context, GameController controller) {
    final dailyMax = controller.dailyBaseCoins + controller.streakBonusCap;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        final palette = GameTheme.ui(sheetContext);
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rule Guide',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'How rewards and difficulties work right now.',
                  style: GameTheme.modeBody(sheetContext),
                ),
                const SizedBox(height: 14),
                _GuideLine(
                  icon: Icons.query_stats_rounded,
                  tint: palette.quickAccent,
                  title: 'Scoring',
                  description:
                      'There is no single score formula yet. Results currently track time, mistakes, and hints. Best time is recorded per mode.',
                ),
                const SizedBox(height: 8),
                _GuideLine(
                  icon: Icons.monetization_on_rounded,
                  tint: palette.successAccent,
                  title: 'Coins',
                  description:
                      'Quick rewards: Easy +${controller.quickEasyCoins}, Medium +${controller.quickMediumCoins}. Daily first clear: +${controller.dailyBaseCoins} plus streak bonus (+${controller.streakBonusPerStep} per day, capped at +${controller.streakBonusCap}, max +$dailyMax).',
                ),
                const SizedBox(height: 8),
                _GuideLine(
                  icon: Icons.extension_rounded,
                  tint: palette.dailyAccent,
                  title: 'Difficulty',
                  description:
                      'Quick Run currently supports Easy and Medium with different puzzle pools. Medium is generally tougher and pays more. Hard is locked for now.',
                ),
                const SizedBox(height: 8),
                _GuideLine(
                  icon: Icons.calendar_today_rounded,
                  tint: palette.hintAccent,
                  title: 'Daily Reset',
                  description:
                      'Daily rewards reset at local midnight. Replaying the same date after claiming will not grant extra daily coins.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int total) {
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _HomeTopHeader extends StatelessWidget {
  const _HomeTopHeader({
    required this.coins,
    required this.onInfoTap,
    required this.onShopTap,
  });

  final int coins;
  final VoidCallback onInfoTap;
  final VoidCallback onShopTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sudoku Loop', style: GameTheme.title(context)),
              const SizedBox(height: 6),
              Text(
                'A bright and chill puzzle menu.',
                style: GameTheme.slogan(context),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _CoinBadge(coins: coins),
        const SizedBox(width: 8),
        _HeaderButton(
          icon: Icons.storefront_rounded,
          onTap: onShopTap,
        ),
        const SizedBox(width: 8),
        _HeaderButton(
          icon: Icons.info_outline_rounded,
          onTap: onInfoTap,
        ),
      ],
    );
  }
}

class _CoinBadge extends StatelessWidget {
  const _CoinBadge({
    required this.coins,
  });

  final int coins;

  @override
  Widget build(BuildContext context) {
    final palette = GameTheme.ui(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.92)),
      ),
      child: Row(
        children: [
          Icon(Icons.monetization_on_rounded,
              size: 18, color: palette.quickAccent),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: GameTheme.chipText(context).copyWith(
              color: palette.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyHeroCard extends StatelessWidget {
  const _DailyHeroCard({
    required this.pulse,
    required this.streak,
    required this.dailyDone,
    required this.hapticEnabled,
    required this.actionLabel,
    required this.onPressed,
  });

  final Animation<double> pulse;
  final int streak;
  final bool dailyDone;
  final bool hapticEnabled;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = GameTheme.ui(context);
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(pulse.value);
        return Transform.scale(
          scale: 1 + (t * 0.01),
          child: child,
        );
      },
      child: _GlassPanel(
        padding: const EdgeInsets.all(22),
        borderRadius: BorderRadius.circular(30),
        colors: const [
          Color(0xF4FFFFFF),
          Color(0xDDF4FFFD),
        ],
        child: Stack(
          children: [
            const Positioned(
              top: -24,
              right: -12,
              child: _GlowDisc(size: 120, color: Color(0x3A7EF7E6)),
            ),
            const Positioned(
              bottom: -32,
              left: -22,
              child: _GlowDisc(size: 146, color: Color(0x42A9FFD0)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: palette.dailyAccent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'TODAY',
                        style: GameTheme.chipText(context).copyWith(
                          color: palette.dailyAccent,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.45,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _StatusTag(
                      label: dailyDone ? 'Completed' : 'Ready',
                      color: dailyDone
                          ? palette.successAccent
                          : palette.quickAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Daily Board',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: palette.textPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  dailyDone
                      ? 'Today is cleared. Replay for a cleaner run or better time.'
                      : 'One curated board each day. Clear it and extend your streak.',
                  style: GameTheme.modeBody(context),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _MetricBadge(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Streak',
                      value: '$streak',
                    ),
                    const SizedBox(width: 10),
                    _MetricBadge(
                      icon: Icons.calendar_today_rounded,
                      label: 'Mode',
                      value: 'Daily',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _GameActionButton(
                  label: actionLabel,
                  icon: Icons.play_arrow_rounded,
                  hapticEnabled: hapticEnabled,
                  onPressed: onPressed,
                  expanded: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickRunCard extends StatelessWidget {
  const _QuickRunCard({
    required this.selected,
    required this.hapticEnabled,
    required this.onDifficultySelected,
    required this.onStart,
  });

  final PuzzleDifficulty selected;
  final bool hapticEnabled;
  final ValueChanged<PuzzleDifficulty> onDifficultySelected;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final palette = GameTheme.ui(context);
    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: palette.quickAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  color: palette.quickAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Run', style: GameTheme.modeTitle(context)),
                    const SizedBox(height: 2),
                    Text(
                      'Choose a pace and jump in instantly.',
                      style: GameTheme.modeBody(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DifficultyChip(
                label: 'Easy',
                selected: selected == PuzzleDifficulty.easy,
                onTap: () => onDifficultySelected(PuzzleDifficulty.easy),
              ),
              _DifficultyChip(
                label: 'Medium',
                selected: selected == PuzzleDifficulty.medium,
                onTap: () => onDifficultySelected(PuzzleDifficulty.medium),
              ),
              const _DifficultyChip(
                label: 'Hard',
                selected: false,
                enabled: false,
                icon: Icons.lock_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _GameActionButton(
            label: 'Start Quick Run',
            icon: Icons.play_arrow_rounded,
            hapticEnabled: hapticEnabled,
            onPressed: onStart,
            gradient: palette.secondaryButtonGradient,
            expanded: true,
          ),
        ],
      ),
    );
  }
}

class _GuideLine extends StatelessWidget {
  const _GuideLine({
    required this.icon,
    required this.tint,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final palette = GameTheme.ui(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tint.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: tint),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GameTheme.chipText(context).copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GameTheme.modeBody(context).copyWith(
                    color: palette.textMuted,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHubCard extends StatelessWidget {
  const _ProgressHubCard({
    required this.totalGames,
    required this.completedDays,
    required this.hapticEnabled,
    required this.onOpenStats,
    required this.onOpenCalendar,
  });

  final int totalGames;
  final int completedDays;
  final bool hapticEnabled;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final palette = GameTheme.ui(context);
    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      borderRadius: BorderRadius.circular(24),
      colors: const [
        Color(0xEEFFFFFF),
        Color(0xDCF8FFFC),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: palette.successAccent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.insights_rounded,
                  color: palette.successAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progress Hub', style: GameTheme.modeTitle(context)),
                    const SizedBox(height: 2),
                    Text(
                      'Track your stats and daily completion calendar.',
                      style: GameTheme.modeBody(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(label: 'Games', value: '$totalGames'),
              _InfoPill(label: 'Daily Clears', value: '$completedDays'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _GameActionButton(
                  label: 'Stats',
                  icon: Icons.query_stats_rounded,
                  hapticEnabled: hapticEnabled,
                  onPressed: onOpenStats,
                  expanded: true,
                  gradient: palette.secondaryButtonGradient,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GameActionButton(
                  label: 'Calendar',
                  icon: Icons.calendar_month_rounded,
                  hapticEnabled: hapticEnabled,
                  onPressed: onOpenCalendar,
                  expanded: true,
                  gradient: palette.primaryButtonGradient,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContinueLastGameCard extends StatelessWidget {
  const _ContinueLastGameCard({
    required this.session,
    required this.elapsedLabel,
    required this.hapticEnabled,
    required this.onResume,
  });

  final GameSession session;
  final String elapsedLabel;
  final bool hapticEnabled;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    return _GlassPanel(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      borderRadius: BorderRadius.circular(22),
      colors: const [
        Color(0xEFFFFFFF),
        Color(0xDDF6FFFA),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Continue Last Game', style: GameTheme.modeTitle(context)),
          const SizedBox(height: 8),
          Text(
            'Pick up exactly where you left off.',
            style: GameTheme.modeBody(context),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(label: 'Mode', value: session.kind.label),
              _InfoPill(
                  label: 'Difficulty', value: session.puzzle.difficulty.label),
              _InfoPill(label: 'Time', value: elapsedLabel),
              _InfoPill(label: 'Mistakes', value: '${session.mistakes}'),
            ],
          ),
          const SizedBox(height: 14),
          _GameActionButton(
            label: 'Resume',
            icon: Icons.play_arrow_rounded,
            hapticEnabled: hapticEnabled,
            onPressed: onResume,
            expanded: false,
          ),
        ],
      ),
    );
  }
}

class _GameActionButton extends StatefulWidget {
  const _GameActionButton({
    required this.label,
    required this.icon,
    required this.hapticEnabled,
    required this.onPressed,
    required this.expanded,
    this.gradient,
  });

  final String label;
  final IconData icon;
  final bool hapticEnabled;
  final VoidCallback onPressed;
  final bool expanded;
  final Gradient? gradient;

  @override
  State<_GameActionButton> createState() => _GameActionButtonState();
}

class _GameActionButtonState extends State<_GameActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.97).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.97, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
        weight: 65,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_busy) return;
    _busy = true;
    try {
      if (widget.hapticEnabled) {
        HapticFeedback.lightImpact();
      }
      _controller.forward(from: 0);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
      widget.onPressed();
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = GameTheme.ui(context);
    final button = ScaleTransition(
      scale: _scale,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            gradient: widget.gradient ?? palette.primaryButtonGradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: palette.buttonShadow,
          ),
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: palette.buttonText,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Icon(widget.icon, color: palette.buttonText),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!widget.expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    required this.padding,
    required this.borderRadius,
    this.colors = const [
      Color(0xEEFFFFFF),
      Color(0xD8FFFFFF),
    ],
  });

  final Widget child;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final palette = GameTheme.ui(context);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            border: Border.all(color: palette.panelStroke),
            boxShadow: palette.panelShadow,
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = GameTheme.ui(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: palette.textMuted),
          const SizedBox(width: 6),
          Text(
            '$label  $value',
            style: GameTheme.chipText(context).copyWith(
              color: palette.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: GameTheme.chipText(context).copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({
    required this.label,
    required this.selected,
    this.enabled = true,
    this.icon,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = GameTheme.ui(context);
    final selectedColor = palette.quickAccent.withValues(alpha: 0.16);
    final borderColor = selected
        ? palette.quickAccent.withValues(alpha: 0.75)
        : const Color(0x80FFFFFF);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color:
              selected ? selectedColor : Colors.white.withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 14,
                    color: enabled ? palette.textMuted : palette.textSubtle,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: GameTheme.chipText(context).copyWith(
                    color: enabled ? palette.textMuted : palette.textSubtle,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = GameTheme.ui(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label  $value',
        style: GameTheme.chipText(context).copyWith(
          color: palette.textMuted,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = GameTheme.ui(context);
    return Material(
      color: Colors.transparent,
      child: Ink(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.92)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Icon(
            icon,
            color: palette.textMuted,
          ),
        ),
      ),
    );
  }
}

class _GlowDisc extends StatelessWidget {
  const _GlowDisc({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameMenuBackground extends StatelessWidget {
  const _GameMenuBackground();

  @override
  Widget build(BuildContext context) {
    final palette = GameTheme.ui(context);
    final accentA = palette.dailyAccent.withValues(alpha: 0.25);
    final accentB = palette.quickAccent.withValues(alpha: 0.22);
    final accentC = palette.successAccent.withValues(alpha: 0.2);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.58, 1.0],
          colors: [
            palette.homeBackgroundTop,
            palette.homeBackgroundMid,
            palette.homeBackgroundBottom,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -84,
            left: -46,
            child: _BackdropOrb(
              size: 246,
              color: accentA,
            ),
          ),
          Positioned(
            top: 120,
            right: -78,
            child: _BackdropOrb(
              size: 270,
              color: accentB,
            ),
          ),
          Positioned(
            bottom: -128,
            left: 24,
            child: _BackdropOrb(
              size: 286,
              color: accentC,
            ),
          ),
          Positioned(
            bottom: 170,
            right: 38,
            child: _BackdropOrb(
              size: 184,
              color: accentA,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
