import 'dart:math';

import '../models/app_enums.dart';
import '../models/sudoku_puzzle.dart';

class PuzzleRepository {
  static const List<int> _bankSeeds = [
    101,
    203,
    307,
    409,
    503,
    601,
    709,
    809,
    907,
    1009,
    1103,
    1201,
  ];

  static const List<_PuzzleTemplate> _templates = [
    _PuzzleTemplate(
      difficulty: PuzzleDifficulty.easy,
      puzzle:
          '530070000600195000098000060800060003400803001700020006060000280000419005000080079',
      solution:
          '534678912672195348198342567859761423426853791713924856961537284287419635345286179',
    ),
    _PuzzleTemplate(
      difficulty: PuzzleDifficulty.medium,
      puzzle:
          '000260701680070090190004500820100040004602900050003028009300074040050036703018000',
      solution:
          '435269781682571493197834562826195347374682915951743628519326874248957136763418259',
    ),
  ];

  SudokuPuzzle quickPlay(PuzzleDifficulty difficulty, int seed) {
    final bankSeed = _bankSeeds[seed.abs() % _bankSeeds.length];
    return _buildPuzzle(
      template: _templateForDifficulty(difficulty, seed),
      seed: bankSeed,
      id: 'quick-${difficulty.name}-$bankSeed',
    );
  }

  SudokuPuzzle dailyChallenge(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final rawSeed = normalized.year * 10000 + normalized.month * 100 + normalized.day;
    final bankSeed = _bankSeeds[rawSeed % _bankSeeds.length] + rawSeed;
    return _buildPuzzle(
      template: _templateForDifficulty(PuzzleDifficulty.medium, rawSeed),
      seed: bankSeed,
      id: 'daily-$rawSeed',
    );
  }

  _PuzzleTemplate _templateForDifficulty(PuzzleDifficulty difficulty, int seed) {
    final options =
        _templates.where((item) => item.difficulty == difficulty).toList();
    return options[seed.abs() % options.length];
  }

  SudokuPuzzle _buildPuzzle({
    required _PuzzleTemplate template,
    required int seed,
    required String id,
  }) {
    final random = Random(seed);
    final digitMap = _digitMap(random);
    final rowMap = _axisMap(random);
    final colMap = _axisMap(random);
    return SudokuPuzzle(
      id: id,
      puzzle: _transform(
        template.puzzle,
        digitMap: digitMap,
        rowMap: rowMap,
        colMap: colMap,
      ),
      solution: _transform(
        template.solution,
        digitMap: digitMap,
        rowMap: rowMap,
        colMap: colMap,
      ),
      difficulty: template.difficulty,
    );
  }

  Map<int, int> _digitMap(Random random) {
    final digits = List<int>.generate(9, (index) => index + 1)..shuffle(random);
    return {
      for (var i = 0; i < 9; i++) i + 1: digits[i],
      0: 0,
    };
  }

  List<int> _axisMap(Random random) {
    final bandOrder = [0, 1, 2]..shuffle(random);
    final rows = <int>[];

    for (final band in bandOrder) {
      final inner = [0, 1, 2]..shuffle(random);
      for (final row in inner) {
        rows.add(band * 3 + row);
      }
    }
    return rows;
  }

  String _transform(
    String raw, {
    required Map<int, int> digitMap,
    required List<int> rowMap,
    required List<int> colMap,
  }) {
    final source = raw.split('').map(int.parse).toList(growable: false);
    final target = List<int>.filled(81, 0);

    for (var row = 0; row < 9; row++) {
      for (var col = 0; col < 9; col++) {
        final sourceIndex = rowMap[row] * 9 + colMap[col];
        target[row * 9 + col] = digitMap[source[sourceIndex]] ?? 0;
      }
    }

    return target.join();
  }
}

class _PuzzleTemplate {
  const _PuzzleTemplate({
    required this.difficulty,
    required this.puzzle,
    required this.solution,
  });

  final PuzzleDifficulty difficulty;
  final String puzzle;
  final String solution;
}
