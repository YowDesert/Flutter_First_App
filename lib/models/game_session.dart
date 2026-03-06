import 'dart:convert';

import 'app_enums.dart';
import 'sudoku_puzzle.dart';

class MoveRecord {
  const MoveRecord({
    required this.index,
    required this.previousValue,
    required this.nextValue,
    required this.previousNotes,
    required this.nextNotes,
  });

  final int index;
  final int previousValue;
  final int nextValue;
  final Set<int> previousNotes;
  final Set<int> nextNotes;
}

class GameSession {
  GameSession({
    required this.puzzle,
    required this.kind,
    required this.values,
    required this.notes,
    required this.elapsedSeconds,
    required this.mistakes,
    required this.hintsUsed,
    required this.challengeDateKey,
    required this.inputMode,
    required this.selectedIndex,
  });

  factory GameSession.fresh({
    required SudokuPuzzle puzzle,
    required GameKind kind,
    String? challengeDateKey,
  }) {
    return GameSession(
      puzzle: puzzle,
      kind: kind,
      values: List<int>.generate(81, puzzle.puzzleValueAt),
      notes: List<Set<int>>.generate(81, (_) => <int>{}),
      elapsedSeconds: 0,
      mistakes: 0,
      hintsUsed: 0,
      challengeDateKey: challengeDateKey,
      inputMode: InputMode.value,
      selectedIndex: null,
    );
  }

  final SudokuPuzzle puzzle;
  final GameKind kind;
  final List<int> values;
  final List<Set<int>> notes;
  final int elapsedSeconds;
  final int mistakes;
  final int hintsUsed;
  final String? challengeDateKey;
  final InputMode inputMode;
  final int? selectedIndex;

  bool get isDaily => kind == GameKind.daily;

  int valueAt(int index) => values[index];

  Set<int> notesAt(int index) => notes[index];

  bool isGiven(int index) => puzzle.isGiven(index);

  bool get isSolved {
    for (var i = 0; i < 81; i++) {
      if (values[i] != puzzle.solutionValueAt(i)) {
        return false;
      }
    }
    return true;
  }

  GameSession copyWith({
    SudokuPuzzle? puzzle,
    GameKind? kind,
    List<int>? values,
    List<Set<int>>? notes,
    int? elapsedSeconds,
    int? mistakes,
    int? hintsUsed,
    String? challengeDateKey,
    InputMode? inputMode,
    int? selectedIndex,
    bool clearSelectedIndex = false,
  }) {
    return GameSession(
      puzzle: puzzle ?? this.puzzle,
      kind: kind ?? this.kind,
      values: values ?? this.values,
      notes: notes ?? this.notes,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      mistakes: mistakes ?? this.mistakes,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      challengeDateKey: challengeDateKey ?? this.challengeDateKey,
      inputMode: inputMode ?? this.inputMode,
      selectedIndex: clearSelectedIndex
          ? null
          : (selectedIndex ?? this.selectedIndex),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'puzzle': puzzle.toJson(),
      'kind': kind.name,
      'values': values,
      'notes': notes.map((item) => item.toList()..sort()).toList(),
      'elapsedSeconds': elapsedSeconds,
      'mistakes': mistakes,
      'hintsUsed': hintsUsed,
      'challengeDateKey': challengeDateKey,
      'inputMode': inputMode.name,
      'selectedIndex': selectedIndex,
    };
  }

  String toStorage() => jsonEncode(toJson());

  static GameSession fromStorage(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final notesJson = (json['notes'] as List<dynamic>? ?? const []);
    return GameSession(
      puzzle: SudokuPuzzle.fromJson(json['puzzle'] as Map<String, dynamic>),
      kind: GameKind.values.firstWhere(
        (item) => item.name == json['kind'],
        orElse: () => GameKind.regular,
      ),
      values: (json['values'] as List<dynamic>).cast<int>(),
      notes: List<Set<int>>.generate(81, (index) {
        if (index >= notesJson.length) {
          return <int>{};
        }
        return (notesJson[index] as List<dynamic>).cast<int>().toSet();
      }),
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      mistakes: json['mistakes'] as int? ?? 0,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      challengeDateKey: json['challengeDateKey'] as String?,
      inputMode: InputMode.values.firstWhere(
        (item) => item.name == json['inputMode'],
        orElse: () => InputMode.value,
      ),
      selectedIndex: json['selectedIndex'] as int?,
    );
  }
}

class GameResult {
  const GameResult({
    required this.elapsedSeconds,
    required this.mistakes,
    required this.hintsUsed,
    required this.difficulty,
    required this.kind,
    required this.challengeDateKey,
    required this.updatedStreak,
  });

  final int elapsedSeconds;
  final int mistakes;
  final int hintsUsed;
  final PuzzleDifficulty difficulty;
  final GameKind kind;
  final String? challengeDateKey;
  final int updatedStreak;

  bool get isDaily => kind == GameKind.daily;
}
