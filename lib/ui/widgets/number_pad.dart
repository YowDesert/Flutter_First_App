import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/game_controller.dart';
import '../../models/app_enums.dart';

class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    this.buttonSize = 44,
    this.fontSize = 20,
    this.padding = 8,
    this.spacing = 6,
    this.borderRadius = 16,
  });

  final double buttonSize;
  final double fontSize;
  final double padding;
  final double spacing;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();
    final session = controller.session;
    if (session == null) {
      return const SizedBox.shrink();
    }

    final selectedIndex = session.selectedIndex;
    final canInput = selectedIndex != null && !session.isGiven(selectedIndex);
    final selectedValue =
        selectedIndex != null ? session.values[selectedIndex] : 0;
    final selectedNotes = selectedIndex != null
        ? Set<int>.from(session.notes[selectedIndex])
        : <int>{};
    final canClear =
        canInput && (selectedValue != 0 || selectedNotes.isNotEmpty);

    return LayoutBuilder(
      builder: (context, constraints) {
        const columns = 5;
        const rows = 2;
        final horizontalGap = spacing.clamp(5.0, 9.0);
        final verticalGap = (spacing + 0.5).clamp(5.0, 9.0);
        final sidePadding = padding.clamp(4.0, 10.0);
        final keypadWidth =
            math.max(0.0, constraints.maxWidth - (sidePadding * 2));
        if (keypadWidth <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }

        final gridCellByWidth = math.max(
          0.0,
          (keypadWidth - (horizontalGap * (columns - 1))) / columns,
        );
        final gridCellByHeight =
            (constraints.maxHeight - (verticalGap * (rows - 1)))
                    .clamp(0.0, double.infinity) /
                rows;
        final buttonHeight = math
            .min(buttonSize + 9.0, gridCellByHeight)
            .clamp(34.0, 68.0)
            .toDouble();
        final touchBase = math.min(gridCellByWidth, buttonHeight);
        final resolvedFont = math
            .min(fontSize + 1.0, math.max(14.0, touchBase * 0.4))
            .toDouble();
        final buttonRadius = math.min(
          borderRadius,
          (touchBase * 0.34).clamp(14.0, 22.0),
        );

        Widget buildDigitButton(int value) {
          final selected = canInput &&
              ((session.inputMode == InputMode.notes && selectedValue == 0)
                  ? selectedNotes.contains(value)
                  : selectedValue == value);
          return SizedBox(
            height: buttonHeight,
            child: KeypadButton(
              label: '$value',
              radius: buttonRadius,
              fontSize: resolvedFont,
              selected: selected,
              enabled: canInput,
              onTap: () => _handleTap(
                controller: controller,
                action: () => controller.inputDigit(value),
              ),
            ),
          );
        }

        Widget buildClearButton() {
          return SizedBox(
            height: buttonHeight,
            child: KeypadButton(
              icon: Icons.backspace_rounded,
              radius: buttonRadius,
              fontSize: resolvedFont * 0.88,
              enabled: canClear,
              utility: true,
              onTap: () => _handleTap(
                controller: controller,
                action: controller.clearSelectedCell,
              ),
            ),
          );
        }

        Widget buildRow(List<Widget> buttons) {
          final children = <Widget>[];
          for (var i = 0; i < buttons.length; i++) {
            if (i > 0) {
              children.add(SizedBox(width: horizontalGap));
            }
            children.add(Expanded(child: buttons[i]));
          }
          return Row(children: children);
        }

        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.86),
                  Colors.white.withValues(alpha: 0.66),
                ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: const Color(0xB6FFFFFF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1C76A3D5),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                buildRow(
                  List.generate(5, (index) => buildDigitButton(index + 1)),
                ),
                SizedBox(height: verticalGap),
                buildRow([
                  buildDigitButton(6),
                  buildDigitButton(7),
                  buildDigitButton(8),
                  buildDigitButton(9),
                  buildClearButton(),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleTap({
    required GameController controller,
    required VoidCallback action,
  }) {
    if (controller.settings.hapticOn) {
      HapticFeedback.selectionClick();
    }
    action();
  }
}

class KeypadButton extends StatefulWidget {
  const KeypadButton({
    super.key,
    this.label,
    this.icon,
    required this.radius,
    required this.fontSize,
    required this.onTap,
    this.enabled = true,
    this.selected = false,
    this.utility = false,
  });

  final String? label;
  final IconData? icon;
  final double radius;
  final double fontSize;
  final VoidCallback onTap;
  final bool enabled;
  final bool selected;
  final bool utility;

  @override
  State<KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<KeypadButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final background = !widget.enabled
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF2F5F9), Color(0xFFE8EDF2)],
          )
        : widget.selected
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF74B1FF), Color(0xFF3787ED)],
              )
            : widget.utility
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFD9BF), Color(0xFFF6B98D)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFFFFF), Color(0xFFF2F7FF)],
                  );

    final foreground = !widget.enabled
        ? const Color(0xFF9BACBF)
        : widget.selected
            ? Colors.white
            : widget.utility
                ? const Color(0xFF9A4A22)
                : const Color(0xFF2D4E76);

    final borderColor = !widget.enabled
        ? const Color(0xFFDCE4ED)
        : widget.selected
            ? const Color(0x903787ED)
            : widget.utility
                ? const Color(0x99EDB386)
                : const Color(0xFFE1EAF5);

    final shadowColor = !widget.enabled
        ? const Color(0x0F657D97)
        : widget.selected
            ? const Color(0x343786ED)
            : widget.utility
                ? const Color(0x26E79C6A)
                : const Color(0x1A6A8DB2);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 120),
      opacity: widget.enabled ? 1.0 : 0.5,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.radius),
          child: Ink(
            decoration: BoxDecoration(
              gradient: background,
              borderRadius: BorderRadius.circular(widget.radius),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: _pressed ? 6 : 12,
                  offset: Offset(0, _pressed ? 2 : 6),
                ),
              ],
            ),
            child: InkWell(
              onTap: widget.enabled ? widget.onTap : null,
              onTapDown: widget.enabled
                  ? (_) => setState(() => _pressed = true)
                  : null,
              onTapUp: widget.enabled
                  ? (_) => setState(() => _pressed = false)
                  : null,
              onTapCancel: widget.enabled
                  ? () => setState(() => _pressed = false)
                  : null,
              borderRadius: BorderRadius.circular(widget.radius),
              splashColor: Colors.white.withValues(alpha: 0.2),
              highlightColor: Colors.transparent,
              child: Center(
                child: widget.icon != null
                    ? Icon(
                        widget.icon,
                        size: math.max(16, widget.fontSize),
                        color: foreground,
                      )
                    : Text(
                        widget.label ?? '',
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: foreground,
                          fontSize: widget.fontSize,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
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
