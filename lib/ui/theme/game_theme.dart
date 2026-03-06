import 'package:flutter/material.dart';

class GameTheme {
  const GameTheme._();

  static const Color seedColor = Color(0xFF16B9A4);

  static const Color backgroundTop = Color(0xFFF2FFF9);
  static const Color backgroundMid = Color(0xFFEAF7FF);
  static const Color backgroundBottom = Color(0xFFFFF8ED);

  static const Color dailyAccent = Color(0xFF16B9A4);
  static const Color quickAccent = Color(0xFF319DFF);
  static const Color dangerAccent = Color(0xFFFF8A8A);
  static const Color successAccent = Color(0xFF31C48D);

  static const Color textPrimary = Color(0xFF14373C);
  static const Color textMuted = Color(0xFF4F6E74);
  static const Color textSubtle = Color(0xFF7E9BA2);
  static const Color panelStroke = Color(0x99FFFFFF);
  static const Color panelBase = Color(0xF2FFFFFF);
  static const Color panelSecondary = Color(0xD8FFFFFF);
  static const Color buttonText = Colors.white;

  static const double radiusLarge = 24;
  static const double radiusMedium = 20;
  static const double radiusSmall = 18;

  static final BorderRadius largeRadius = BorderRadius.circular(radiusLarge);
  static final BorderRadius mediumRadius = BorderRadius.circular(radiusMedium);
  static final BorderRadius smallRadius = BorderRadius.circular(radiusSmall);

  static const List<BoxShadow> panelShadow = [
    BoxShadow(
      color: Color(0x1A2B5C74),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color(0x3322A890),
      blurRadius: 14,
      offset: Offset(0, 8),
    ),
  ];

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2FD6BF),
      Color(0xFF16B9A4),
    ],
  );

  static const LinearGradient secondaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF67C0FF),
      Color(0xFF319DFF),
    ],
  );

  static TextStyle title(BuildContext context) {
    return Theme.of(context).textTheme.headlineLarge!.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.0,
          height: 1.0,
        );
  }

  static TextStyle slogan(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.copyWith(
          color: textMuted,
          fontWeight: FontWeight.w500,
          height: 1.35,
        );
  }

  static TextStyle sectionTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.1,
        );
  }

  static TextStyle modeTitle(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        );
  }

  static TextStyle modeBody(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: textMuted,
          height: 1.4,
          fontWeight: FontWeight.w500,
        );
  }

  static TextStyle chipText(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge!.copyWith(
          color: textMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        );
  }
}
