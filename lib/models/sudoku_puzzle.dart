import 'dart:convert';

import 'app_enums.dart';

class SudokuPuzzle {
  const SudokuPuzzle({
    required this.id,
    required this.puzzle,
    required this.solution,
    required this.difficulty,
  });

  final String id;
  final String puzzle;
  final String solution;
  final PuzzleDifficulty difficulty;

  int puzzleValueAt(int index) => int.parse(puzzle[index]);

  int solutionValueAt(int index) => int.parse(solution[index]);

  bool isGiven(int index) => puzzleValueAt(index) != 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'puzzle': puzzle,
      'solution': solution,
      'difficulty': difficulty.name,
    };
  }

  String toStorage() => jsonEncode(toJson());

  static SudokuPuzzle fromJson(Map<String, dynamic> json) {
    return SudokuPuzzle(
      id: json['id'] as String,
      puzzle: json['puzzle'] as String,
      solution: json['solution'] as String,
      difficulty: PuzzleDifficulty.values.firstWhere(
        (item) => item.name == json['difficulty'],
        orElse: () => PuzzleDifficulty.medium,
      ),
    );
  }

  static SudokuPuzzle fromStorage(String raw) {
    return fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
