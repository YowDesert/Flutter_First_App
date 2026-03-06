import 'dart:math';
import '../models/board.dart';
import 'solver.dart';
import 'difficulty.dart';

class Generator {
  final Random _rand;
  Board? solution;

  Generator(int seed) : _rand = Random(seed);

  Board generate(Difficulty diff) {
    final config = diff.config;
    Board b = Board(0);
    _fill(b);
    solution = Board.clone(b);

    final holes = config.holes;
    final cells = List.generate(81, (i) => i)..shuffle(_rand);
    Solver solver = Solver();

    var removed = 0;
    final visited = <int>{};
    for (final idx in cells) {
      if (removed >= holes) break;
      if (visited.contains(idx)) continue;

      final pair = config.useSymmetry ? _mirrorIndex(idx) : idx;
      final targets = pair == idx ? [idx] : [idx, pair];
      if (removed + targets.length > holes) continue;

      final backups = <int>[];
      for (final target in targets) {
        visited.add(target);
        final r = target ~/ 9;
        final c = target % 9;
        backups.add(b.at(r, c).value);
        b.at(r, c).value = 0;
      }

      if (solver.countSolutions(b) == 1) {
        removed += targets.length;
      } else {
        for (var i = 0; i < targets.length; i++) {
          final r = targets[i] ~/ 9;
          final c = targets[i] % 9;
          b.at(r, c).value = backups[i];
        }
      }
    }

    b.markGiven();
    return b;
  }

  int _mirrorIndex(int idx) => 80 - idx;

  bool _fill(Board b) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (b.at(r, c).isEmpty) {
          List<int> vals = List.generate(9, (i) => i + 1)..shuffle(_rand);
          for (int v in vals) {
            if (b.isValidMove(r, c, v)) {
              b.at(r, c).value = v;
              if (_fill(b)) return true;
              b.at(r, c).value = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }
}
