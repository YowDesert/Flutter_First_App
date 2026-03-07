import '../models/app_enums.dart';
import '../models/board.dart';
import '../models/sudoku_puzzle.dart';
import '../sudoku/difficulty.dart';
import '../sudoku/generator.dart';

class PuzzleRepository {
  SudokuPuzzle quickPlay(PuzzleDifficulty difficulty, int seed) {
    return _buildGeneratedPuzzle(
      generationDifficulty: _toGeneratorDifficulty(difficulty),
      seed: seed,
      id: 'quick-${difficulty.name}-${seed.abs()}',
      puzzleDifficulty: difficulty,
    );
  }

  SudokuPuzzle dailyChallenge(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final rawSeed =
        normalized.year * 10000 + normalized.month * 100 + normalized.day;
    return _buildGeneratedPuzzle(
      generationDifficulty: Difficulty.daily,
      seed: rawSeed,
      id: 'daily-$rawSeed',
      puzzleDifficulty: PuzzleDifficulty.medium,
    );
  }

  SudokuPuzzle _buildGeneratedPuzzle({
    required Difficulty generationDifficulty,
    required int seed,
    required String id,
    required PuzzleDifficulty puzzleDifficulty,
  }) {
    final generator = Generator(seed);
    final puzzleBoard = generator.generate(generationDifficulty);
    final solutionBoard = generator.solution ?? Board.clone(puzzleBoard);

    return SudokuPuzzle(
      id: id,
      puzzle: _boardToDigits(puzzleBoard),
      solution: _boardToDigits(solutionBoard),
      difficulty: puzzleDifficulty,
    );
  }

  Difficulty _toGeneratorDifficulty(PuzzleDifficulty difficulty) {
    switch (difficulty) {
      case PuzzleDifficulty.easy:
        return Difficulty.easy;
      case PuzzleDifficulty.medium:
        return Difficulty.medium;
    }
  }

  String _boardToDigits(Board board) {
    final buffer = StringBuffer();
    for (var row = 0; row < 9; row++) {
      for (var col = 0; col < 9; col++) {
        buffer.write(board.at(row, col).value);
      }
    }
    return buffer.toString();
  }
}
