import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sudoku/data/puzzle_repository.dart';
import 'package:flutter_sudoku/models/app_enums.dart';

void main() {
  group('PuzzleRepository', () {
    final repository = PuzzleRepository();

    test('quick play is deterministic with same seed', () {
      final first = repository.quickPlay(PuzzleDifficulty.easy, 123456);
      final second = repository.quickPlay(PuzzleDifficulty.easy, 123456);

      expect(second.puzzle, first.puzzle);
      expect(second.solution, first.solution);
    });

    test('quick play usually differs with different seeds', () {
      final first = repository.quickPlay(PuzzleDifficulty.medium, 123456);
      final second = repository.quickPlay(PuzzleDifficulty.medium, 123457);

      expect(second.id, isNot(first.id));
      expect(second.puzzle, isNot(first.puzzle));
    });

    test('daily challenge is deterministic for the same date', () {
      final date = DateTime(2026, 3, 7);
      final first = repository.dailyChallenge(date);
      final second = repository.dailyChallenge(date);

      expect(second.puzzle, first.puzzle);
      expect(second.solution, first.solution);
    });

    test('easy has more givens than medium on average', () {
      const seeds = [101, 203, 307, 409, 503];
      var easyGivens = 0;
      var mediumGivens = 0;

      for (final seed in seeds) {
        easyGivens += _countGivens(
          repository.quickPlay(PuzzleDifficulty.easy, seed).puzzle,
        );
        mediumGivens += _countGivens(
          repository.quickPlay(PuzzleDifficulty.medium, seed).puzzle,
        );
      }

      expect(easyGivens, greaterThan(mediumGivens));
    });
  });
}

int _countGivens(String puzzle) =>
    puzzle.split('').where((char) => char != '0').length;
