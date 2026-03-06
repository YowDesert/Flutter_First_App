import '../models/board.dart';

class Solver {
  /// solve board in-place; return true if solved.
  bool solve(Board b) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (b.at(r, c).isEmpty) {
          for (int v = 1; v <= 9; v++) {
            if (b.isValidMove(r, c, v)) {
              b.at(r, c).value = v;
              if (solve(b)) return true;
              b.at(r, c).value = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  /// count solutions up to [limit]; stops when reached.
  int countSolutions(Board b, {int limit = 2}) {
    if (!_hasValidState(b)) {
      return 0;
    }

    int count = 0;
    void dfs(Board cur) {
      if (count >= limit) return;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (cur.at(r, c).isEmpty) {
            for (int v = 1; v <= 9; v++) {
              if (count >= limit) return;
              if (cur.isValidMove(r, c, v)) {
                cur.at(r, c).value = v;
                dfs(cur);
                cur.at(r, c).value = 0;
              }
            }
            return;
          }
        }
      }
      count++;
    }

    dfs(Board.clone(b));
    return count;
  }

  bool _hasValidState(Board board) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final value = board.at(row, col).value;
        if (value == 0) {
          continue;
        }
        board.at(row, col).value = 0;
        final isValid = board.isValidMove(row, col, value);
        board.at(row, col).value = value;
        if (!isValid) {
          return false;
        }
      }
    }
    return true;
  }
}
