import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_sudoku/controllers/game_controller.dart';
import 'package:flutter_sudoku/models/app_enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameController', () {
    test('notes mode toggles and undo restores note state', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = GameController(prefs);

      controller.startQuickGame(PuzzleDifficulty.easy);
      final index = _findEditableIndex(controller);
      controller.selectCell(index ~/ 9, index % 9);
      controller.toggleInputMode();
      controller.inputDigit(3);

      expect(controller.session!.notes[index], contains(3));

      controller.undo();

      expect(controller.session!.notes[index], isEmpty);
    });

    test('instant mode marks wrong input immediately', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = GameController(prefs);

      controller.startQuickGame(PuzzleDifficulty.easy);
      controller.updateErrorMode(ErrorMode.instant);
      final index = _findEditableIndex(controller);
      controller.selectCell(index ~/ 9, index % 9);
      controller.inputDigit(_wrongDigit(controller, index));

      expect(controller.visibleErrorIndexes, contains(index));
      expect(controller.session!.mistakes, 1);
    });

    test('check only mode hides wrong input until check', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = GameController(prefs);

      controller.startQuickGame(PuzzleDifficulty.medium);
      controller.updateErrorMode(ErrorMode.checkOnly);
      final index = _findEditableIndex(controller);
      controller.selectCell(index ~/ 9, index % 9);
      controller.inputDigit(_wrongDigit(controller, index));

      expect(controller.visibleErrorIndexes, isEmpty);
      expect(controller.checkBoard(), 1);
      expect(controller.visibleErrorIndexes, contains(index));
    });

    test('hint fills selected cell and increments hint counter', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = GameController(prefs);

      controller.startQuickGame(PuzzleDifficulty.easy);
      final index = _findEditableIndex(controller);
      controller.selectCell(index ~/ 9, index % 9);

      controller.useHint();

      expect(
          controller.session!.values[index], _correctDigit(controller, index));
      expect(controller.session!.hintsUsed, 1);
      expect(controller.canUndo, isTrue);

      controller.undo();

      expect(controller.session!.values[index], 0);
      expect(controller.session!.hintsUsed, 1);
    });

    test('hint auto-selects an empty editable cell when none is selected',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = GameController(prefs);

      controller.startQuickGame(PuzzleDifficulty.medium);
      expect(controller.session!.selectedIndex, isNull);

      controller.useHint();

      final hintedIndex = controller.session!.selectedIndex;
      expect(hintedIndex, isNotNull);
      expect(controller.session!.isGiven(hintedIndex!), isFalse);
      expect(
        controller.session!.values[hintedIndex],
        _correctDigit(controller, hintedIndex),
      );
      expect(controller.session!.hintsUsed, 1);
    });

    test('hint handles completed board without errors', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = GameController(prefs);

      controller.startQuickGame(PuzzleDifficulty.easy);
      while (controller.canUseHint) {
        controller.useHint();
      }

      expect(controller.session, isNull);
      expect(controller.lastResult, isNotNull);
      expect(controller.lastResult!.hintsUsed, greaterThan(0));
      expect(() => controller.useHint(), returnsNormally);
    });

    test('daily challenge is deterministic for the same date', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = GameController(prefs);
      final date = DateTime(2026, 3, 4);

      controller.startDailyChallenge(date);
      final firstPuzzle = controller.session!.puzzle.puzzle;
      final firstSolution = controller.session!.puzzle.solution;

      controller.startDailyChallenge(date);

      expect(controller.session!.puzzle.puzzle, firstPuzzle);
      expect(controller.session!.puzzle.solution, firstSolution);
    });

    test('session is restored from local storage', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = GameController(prefs);

      controller.startQuickGame(PuzzleDifficulty.easy);
      final index = _findEditableIndex(controller);
      controller.selectCell(index ~/ 9, index % 9);
      controller.inputDigit(_correctDigit(controller, index));

      final restoredPrefs = await SharedPreferences.getInstance();
      final restored = GameController(restoredPrefs);

      expect(restored.session, isNotNull);
      expect(restored.session!.values[index], _correctDigit(controller, index));
    });
  });
}

int _findEditableIndex(GameController controller) {
  for (var index = 0; index < 81; index++) {
    if (!controller.session!.isGiven(index)) {
      return index;
    }
  }
  throw StateError('No editable cell found.');
}

int _correctDigit(GameController controller, int index) {
  return controller.session!.puzzle.solutionValueAt(index);
}

int _wrongDigit(GameController controller, int index) {
  final correct = _correctDigit(controller, index);
  for (var digit = 1; digit <= 9; digit++) {
    if (digit != correct) {
      return digit;
    }
  }
  throw StateError('No wrong digit found.');
}
