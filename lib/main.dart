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
    return ChangeNotifierProvider(
      create: (_) => GameController(prefs),
      child: Consumer<GameController>(
        builder: (context, controller, _) {
          return MaterialApp(
            title: 'Sudoku',
            debugShowCheckedModeBanner: false,
            theme: GameTheme.buildThemeData(
              themeSkin: controller.equippedTheme,
              boardSkin: controller.equippedBoardSkin,
            ),
            home: const SplashPage(),
          );
        },
      ),
    );
  }
}
