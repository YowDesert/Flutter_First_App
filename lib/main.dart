import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/game_controller.dart';
import 'ui/pages/splash_page.dart';
import 'ui/theme/game_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: GameTheme.seedColor,
      brightness: Brightness.light,
    );
    final cardShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));

    return ChangeNotifierProvider(
      create: (_) => GameController(prefs),
      child: MaterialApp(
        title: 'Sudoku Loop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: baseScheme.copyWith(
            primary: GameTheme.seedColor,
            secondary: GameTheme.quickAccent,
            tertiary: GameTheme.successAccent,
            surface: const Color(0xFFF7FBFA),
            surfaceContainer: const Color(0xFFFFFFFF),
          ),
          scaffoldBackgroundColor: const Color(0xFFF3FBF8),
          cardTheme: CardThemeData(
            elevation: 0,
            color: Colors.white.withValues(alpha: 0.94),
            shape: cardShape,
            margin: EdgeInsets.zero,
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              side: BorderSide(color: baseScheme.outlineVariant),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          chipTheme: ChipThemeData(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: BorderSide(color: baseScheme.outlineVariant),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            backgroundColor: Colors.white,
            selectedColor: baseScheme.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
          ),
        ),
        home: const SplashPage(),
      ),
    );
  }
}
