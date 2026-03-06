enum PuzzleDifficulty { easy, medium }

extension PuzzleDifficultyX on PuzzleDifficulty {
  String get label => this == PuzzleDifficulty.easy ? 'Easy' : 'Medium';
}

enum GameKind { regular, daily }

extension GameKindX on GameKind {
  String get label => this == GameKind.daily ? 'Daily Challenge' : 'Quick Play';
}

enum InputMode { value, notes }

extension InputModeX on InputMode {
  String get label => this == InputMode.notes ? 'Notes' : 'Number';
}

enum ErrorMode { instant, checkOnly, off }

extension ErrorModeX on ErrorMode {
  String get label {
    switch (this) {
      case ErrorMode.instant:
        return 'Instant';
      case ErrorMode.checkOnly:
        return 'Check Only';
      case ErrorMode.off:
        return 'Hardcore';
    }
  }

  String get description {
    switch (this) {
      case ErrorMode.instant:
        return 'Wrong numbers are marked immediately.';
      case ErrorMode.checkOnly:
        return 'Only show mistakes after pressing Check.';
      case ErrorMode.off:
        return 'No error checking.';
    }
  }
}

class CellPosition {
  const CellPosition(this.row, this.col);

  final int row;
  final int col;

  int get index => row * 9 + col;

  static CellPosition fromIndex(int index) => CellPosition(index ~/ 9, index % 9);
}
