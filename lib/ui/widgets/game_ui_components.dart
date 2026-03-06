import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import '../../models/app_enums.dart';

class GameCircleIconButton extends StatefulWidget {
  const GameCircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tint = const Color(0xFF2E6FD2),
    this.size = 42,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color tint;
  final double size;

  @override
  State<GameCircleIconButton> createState() => _GameCircleIconButtonState();
}

class _GameCircleIconButtonState extends State<GameCircleIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final shadowColor = widget.tint.withValues(alpha: 0.18);
    return AnimatedScale(
      duration: const Duration(milliseconds: 110),
      scale: _pressed ? 0.95 : 1,
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFDFEFF), Color(0xFFEAF3FF)],
            ),
            border: Border.all(color: const Color(0xB8FFFFFF)),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: _pressed ? 7 : 14,
                offset: Offset(0, _pressed ? 2 : 7),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.size / 2),
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            splashColor: widget.tint.withValues(alpha: 0.12),
            highlightColor: Colors.transparent,
            child:
                Icon(widget.icon, color: widget.tint, size: widget.size * 0.52),
          ),
        ),
      ),
    );
  }
}

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    this.iconSize = 16,
    this.labelFontSize = 11,
    this.valueFontSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    this.borderRadius = 16,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final double iconSize;
  final double labelFontSize;
  final double valueFontSize;
  final EdgeInsets padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: tint.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: tint.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: iconSize * 1.95,
            height: iconSize * 1.95,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: iconSize, color: tint),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: const Color(0xFF5F738B),
                    fontSize: labelFontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.18),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    value,
                    key: ValueKey('$label-$value'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tint,
                      fontWeight: FontWeight.w900,
                      fontSize: valueFontSize,
                    ),
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

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    this.height = 60,
    this.padding = 8,
    this.gap = 4,
    this.borderRadius = 16,
    this.iconSize = 18,
    this.fontSize = 11,
  });

  final double height;
  final double padding;
  final double gap;
  final double borderRadius;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final session = controller.session;
    if (session == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: height,
      child: Container(
        padding: EdgeInsets.all(
          math.min(
            padding,
            math.max(4.0, (height - 32.0) / 2),
          ),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.86),
              Colors.white.withValues(alpha: 0.68),
            ],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: const Color(0xB6FFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A7AA4D8),
              blurRadius: 22,
              offset: Offset(0, 9),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _ActionPill(
                icon: session.inputMode == InputMode.notes
                    ? Icons.edit_note_rounded
                    : Icons.border_color_rounded,
                label: 'Notes',
                selected: session.inputMode == InputMode.notes,
                enabled: true,
                iconSize: iconSize,
                fontSize: fontSize,
                onTap: controller.toggleInputMode,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _ActionPill(
                icon: Icons.undo_rounded,
                label: 'Undo',
                selected: false,
                enabled: controller.canUndo,
                iconSize: iconSize,
                fontSize: fontSize,
                onTap: controller.canUndo ? controller.undo : null,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _ActionPill(
                icon: Icons.redo_rounded,
                label: 'Redo',
                selected: false,
                enabled: controller.canRedo,
                iconSize: iconSize,
                fontSize: fontSize,
                onTap: controller.canRedo ? controller.redo : null,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _ActionPill(
                icon: Icons.fact_check_rounded,
                label: 'Check',
                selected: false,
                enabled: controller.settings.errorMode != ErrorMode.off,
                accentColor: const Color(0xFF2B9D7E),
                iconSize: iconSize,
                fontSize: fontSize,
                onTap: () => controller.checkBoard(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.iconSize,
    required this.fontSize,
    required this.onTap,
    this.accentColor = const Color(0xFF357DE6),
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final double iconSize;
  final double fontSize;
  final VoidCallback? onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final background = !enabled
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF1F4F8), Color(0xFFE8EDF3)],
          )
        : selected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accentColor.withValues(alpha: 0.82), accentColor],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFF1F5FA)],
              );
    final foreground = !enabled
        ? const Color(0xFF94A3B8)
        : selected
            ? Colors.white
            : const Color(0xFF2A466A);
    final borderColor = !enabled
        ? const Color(0xFFDBE3EC)
        : selected
            ? accentColor.withValues(alpha: 0.55)
            : const Color(0xFFE0E9F2);
    final shadowColor = selected
        ? accentColor.withValues(alpha: 0.26)
        : const Color(0x146985A4);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: selected ? 12 : 10,
                offset: Offset(0, selected ? 5 : 4),
              ),
            ],
          ),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            splashColor: Colors.white.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          icon,
                          key: ValueKey('$label-$selected'),
                          size: iconSize,
                          color: foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        selected ? '$label On' : label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                          fontSize: fontSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
