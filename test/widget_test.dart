import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sudoku/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app opens splash screen first', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(MyApp(prefs: prefs));
    await tester.pump(const Duration(milliseconds: 160));

    expect(find.text('Sudoku'), findsOneWidget);
    expect(find.text('Tap to Start'), findsOneWidget);
  });
}
