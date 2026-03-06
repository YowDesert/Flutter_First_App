import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/puzzle_repository.dart';
import '../models/app_enums.dart';
import '../models/daily_progress.dart';
import '../models/game_session.dart';
import '../models/game_settings.dart';
import '../models/sudoku_puzzle.dart';

class GameController extends ChangeNotifier {
  GameController(this._prefs) {
    _restoreFromPrefs();
  }

  static const int? _hintLimit = null;
  static const _settingsKey = 'settings_v2';
  static const _dailyProgressKey = 'daily_progress_v2';
  static const _activeSessionKey = 'active_session_v2';

  final SharedPreferences _prefs;
  final PuzzleRepository _repository = PuzzleRepository();

  GameSettings _settings = const GameSettings();
  DailyProgress _dailyProgress = DailyProgress();
  GameSession? _session;
  GameResult? _lastResult;
  Timer? _timer;
  final List<MoveRecord> _undoStack = <MoveRecord>[];
  final List<MoveRecord> _redoStack = <MoveRecord>[];
  Set<int> _visibleErrorIndexes = <int>{};
  int? _recentErrorIndex;
  int _feedbackVersion = 0;
  String? _message;
  int _messageVersion = 0;

  GameSettings get settings => _settings;
  DailyProgress get dailyProgress => _dailyProgress;
  GameSession? get session => _session;
  GameResult? get lastResult => _lastResult;
  Set<int> get visibleErrorIndexes => _visibleErrorIndexes;
  int? get recentErrorIndex => _recentErrorIndex;
  int get feedbackVersion => _feedbackVersion;
  String? get message => _message;
  int get messageVersion => _messageVersion;
  bool get hasActiveSession => _session != null;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  int get hintCount => _session?.hintsUsed ?? 0;
  int? get hintLimit => _hintLimit;
  int? get remainingHints {
    final current = _session;
    final limit = _hintLimit;
    if (current == null || limit == null) {
      return null;
    }
    final remaining = limit - current.hintsUsed;
    return remaining > 0 ? remaining : 0;
  }

  bool get canUseHint {
    final current = _session;
    if (current == null || current.isSolved) {
      return false;
    }
    final remaining = remainingHints;
    if (remaining != null && remaining <= 0) {
      return false;
    }
    return _findHintTargetIndex(current) != null;
  }

  void startQuickGame(PuzzleDifficulty difficulty) {
    final seed = DateTime.now().microsecondsSinceEpoch;
    _startSession(
      _repository.quickPlay(difficulty, seed),
      kind: GameKind.regular,
    );
  }

  void startDailyChallenge([DateTime? date]) {
    final target = date ?? DateTime.now();
    _startSession(
      _repository.dailyChallenge(target),
      kind: GameKind.daily,
      challengeDateKey: _dateKey(target),
    );
  }

  void selectCell(int row, int col) {
    final current = _session;
    if (current == null) return;
    _session = current.copyWith(selectedIndex: row * 9 + col);
    notifyListeners();
    _persistSession();
  }

  void toggleInputMode() {
    final current = _session;
    if (current == null) return;
    _session = current.copyWith(
      inputMode: current.inputMode == InputMode.value
          ? InputMode.notes
          : InputMode.value,
    );
    notifyListeners();
    _persistSession();
  }

  void inputDigit(int digit) {
    final current = _session;
    if (current == null || current.selectedIndex == null) return;
    final index = current.selectedIndex!;
    if (current.isGiven(index)) return;

    final previousValue = current.values[index];
    final previousNotes = Set<int>.from(current.notes[index]);
    int nextValue = previousValue;
    Set<int> nextNotes = previousNotes;

    if (current.inputMode == InputMode.notes && previousValue == 0) {
      nextNotes = Set<int>.from(previousNotes);
      if (nextNotes.contains(digit)) {
        nextNotes.remove(digit);
      } else {
        nextNotes.add(digit);
      }
    } else {
      if (previousValue == digit) return;
      nextValue = digit;
      nextNotes = <int>{};
    }

    _applyMove(
      MoveRecord(
        index: index,
        previousValue: previousValue,
        nextValue: nextValue,
        previousNotes: previousNotes,
        nextNotes: nextNotes,
      ),
    );
  }

  void clearSelectedCell() {
    final current = _session;
    if (current == null || current.selectedIndex == null) return;
    final index = current.selectedIndex!;
    if (current.isGiven(index)) return;
    if (current.values[index] == 0 && current.notes[index].isEmpty) return;

    _applyMove(
      MoveRecord(
        index: index,
        previousValue: current.values[index],
        nextValue: 0,
        previousNotes: Set<int>.from(current.notes[index]),
        nextNotes: <int>{},
      ),
    );
  }

  void undo() {
    if (_session == null || _undoStack.isEmpty) return;
    final move = _undoStack.removeLast();
    _redoStack.add(move);
    _session = _replaceCell(
      _session!,
      index: move.index,
      value: move.previousValue,
      notes: move.previousNotes,
    );
    _syncVisibleErrors();
    notifyListeners();
    _persistSession();
  }

  void redo() {
    if (_session == null || _redoStack.isEmpty) return;
    final move = _redoStack.removeLast();
    _undoStack.add(move);
    _session = _replaceCell(
      _session!,
      index: move.index,
      value: move.nextValue,
      notes: move.nextNotes,
    );
    _postValueMutation(move.index);
  }

  void useHint() {
    final current = _session;
    if (current == null) return;
    if (current.isSolved) {
      _pushMessage('Board is already complete.');
      notifyListeners();
      return;
    }
    final remaining = remainingHints;
    if (remaining != null && remaining <= 0) {
      _pushMessage('No hints left.');
      notifyListeners();
      return;
    }

    final targetIndex = _findHintTargetIndex(current);
    if (targetIndex == null) {
      _pushMessage('No hint available right now.');
      notifyListeners();
      return;
    }

    final solutionValue = current.puzzle.solutionValueAt(targetIndex);
    final position = CellPosition.fromIndex(targetIndex);
    _pushMessage(
      'Hint: R${position.row + 1}C${position.col + 1} = $solutionValue',
    );

    if (current.selectedIndex != targetIndex) {
      _session = current.copyWith(selectedIndex: targetIndex);
    }

    _applyMove(
      MoveRecord(
        index: targetIndex,
        previousValue: current.values[targetIndex],
        nextValue: solutionValue,
        previousNotes: Set<int>.from(current.notes[targetIndex]),
        nextNotes: <int>{},
      ),
      consumedHint: true,
    );
  }

  int? checkBoard() {
    final current = _session;
    if (current == null) return null;
    if (_settings.errorMode == ErrorMode.off) {
      _pushMessage('Check is disabled in Hardcore mode.');
      notifyListeners();
      return null;
    }

    _visibleErrorIndexes = _collectWrongIndexes(current);
    final count = _visibleErrorIndexes.length;
    _pushMessage(count == 0 ? 'No mistakes found.' : '$count mistakes found.');
    notifyListeners();
    _persistSession();
    return count;
  }

  void updateErrorMode(ErrorMode mode) {
    _settings = _settings.copyWith(errorMode: mode);
    _syncVisibleErrors();
    _persistSettings();
    notifyListeners();
  }

  void updateSound(bool enabled) {
    _settings = _settings.copyWith(soundOn: enabled);
    _persistSettings();
    notifyListeners();
  }

  void updateHaptic(bool enabled) {
    _settings = _settings.copyWith(hapticOn: enabled);
    _persistSettings();
    notifyListeners();
  }

  void clearMessage() {
    _message = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restoreFromPrefs() {
    _settings = GameSettings.fromStorage(_prefs.getString(_settingsKey));
    _dailyProgress =
        DailyProgress.fromStorage(_prefs.getString(_dailyProgressKey));
    final rawSession = _prefs.getString(_activeSessionKey);
    if (rawSession != null && rawSession.isNotEmpty) {
      _session = GameSession.fromStorage(rawSession);
      _syncVisibleErrors();
      _startTimer();
    }
  }

  void _startSession(
    SudokuPuzzle puzzle, {
    required GameKind kind,
    String? challengeDateKey,
  }) {
    _timer?.cancel();
    _session = GameSession.fresh(
      puzzle: puzzle,
      kind: kind,
      challengeDateKey: challengeDateKey,
    );
    _lastResult = null;
    _undoStack.clear();
    _redoStack.clear();
    _visibleErrorIndexes = <int>{};
    _recentErrorIndex = null;
    _feedbackVersion = 0;
    _message = null;
    _startTimer();
    notifyListeners();
    _persistSession();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = _session;
      if (current == null) return;
      _session = current.copyWith(elapsedSeconds: current.elapsedSeconds + 1);
      notifyListeners();
      _persistSession();
    });
  }

  void _applyMove(MoveRecord move, {bool consumedHint = false}) {
    final current = _session;
    if (current == null) return;
    final didChange = move.previousValue != move.nextValue ||
        move.previousNotes.length != move.nextNotes.length ||
        !move.previousNotes.containsAll(move.nextNotes);
    if (!didChange) {
      return;
    }

    _undoStack.add(move);
    _redoStack.clear();
    _session = _replaceCell(
      current,
      index: move.index,
      value: move.nextValue,
      notes: move.nextNotes,
    );
    if (consumedHint) {
      final updated = _session;
      if (updated != null) {
        _session = updated.copyWith(hintsUsed: updated.hintsUsed + 1);
      }
    }
    _postValueMutation(move.index);
  }

  int? _findHintTargetIndex(GameSession current) {
    final selected = current.selectedIndex;
    if (selected != null && _isHintCandidate(current, selected)) {
      return selected;
    }

    for (var index = 0; index < 81; index++) {
      if (_isHintCandidate(current, index) && current.values[index] == 0) {
        return index;
      }
    }

    for (var index = 0; index < 81; index++) {
      if (_isHintCandidate(current, index)) {
        return index;
      }
    }
    return null;
  }

  bool _isHintCandidate(GameSession current, int index) {
    if (current.isGiven(index)) {
      return false;
    }
    return current.values[index] != current.puzzle.solutionValueAt(index);
  }

  GameSession _replaceCell(
    GameSession current, {
    required int index,
    required int value,
    required Set<int> notes,
  }) {
    final nextValues = List<int>.from(current.values);
    final nextNotes = current.notes.map((item) => Set<int>.from(item)).toList();
    nextValues[index] = value;
    nextNotes[index] = Set<int>.from(notes);
    return current.copyWith(values: nextValues, notes: nextNotes);
  }

  void _postValueMutation(int index) {
    final current = _session;
    if (current == null) return;

    if (current.inputMode == InputMode.notes && current.values[index] == 0) {
      notifyListeners();
      _persistSession();
      return;
    }

    final isWrong = current.values[index] != 0 &&
        current.values[index] != current.puzzle.solutionValueAt(index);

    if (isWrong) {
      _session = current.copyWith(mistakes: current.mistakes + 1);
    }

    if (isWrong && _settings.errorMode == ErrorMode.instant) {
      _registerError(index, message: 'That number does not fit here.');
    } else if (!isWrong) {
      _playSuccessFeedback();
      _recentErrorIndex = null;
    } else {
      _recentErrorIndex = null;
    }

    _syncVisibleErrors();
    notifyListeners();
    _persistSession();

    if (_session!.isSolved) {
      _completeSession();
    }
  }

  void _registerError(int index, {required String message}) {
    _recentErrorIndex = index;
    _feedbackVersion += 1;
    _playErrorFeedback();
    _pushMessage(message);
  }

  void _syncVisibleErrors() {
    final current = _session;
    if (current == null) {
      _visibleErrorIndexes = <int>{};
      return;
    }

    switch (_settings.errorMode) {
      case ErrorMode.instant:
        _visibleErrorIndexes = _collectWrongIndexes(current);
        break;
      case ErrorMode.checkOnly:
        _visibleErrorIndexes = _visibleErrorIndexes
            .where((index) => current.values[index] != 0)
            .where((index) =>
                current.values[index] != current.puzzle.solutionValueAt(index))
            .toSet();
        break;
      case ErrorMode.off:
        _visibleErrorIndexes = <int>{};
        break;
    }
  }

  Set<int> _collectWrongIndexes(GameSession current) {
    final wrong = <int>{};
    for (var index = 0; index < 81; index++) {
      final value = current.values[index];
      if (value == 0) continue;
      if (value != current.puzzle.solutionValueAt(index)) {
        wrong.add(index);
      }
    }
    return wrong;
  }

  void _completeSession() {
    final current = _session;
    if (current == null) return;
    _timer?.cancel();

    if (current.isDaily && current.challengeDateKey != null) {
      final challengeDate = DateTime.parse(current.challengeDateKey!);
      _dailyProgress = _dailyProgress.registerCompletion(
        current.challengeDateKey!,
        _dateKey(challengeDate.subtract(const Duration(days: 1))),
      );
      _persistDailyProgress();
    }

    _lastResult = GameResult(
      elapsedSeconds: current.elapsedSeconds,
      mistakes: current.mistakes,
      hintsUsed: current.hintsUsed,
      difficulty: current.puzzle.difficulty,
      kind: current.kind,
      challengeDateKey: current.challengeDateKey,
      updatedStreak: _dailyProgress.streak,
    );
    _session = null;
    _undoStack.clear();
    _redoStack.clear();
    _visibleErrorIndexes = <int>{};
    _prefs.remove(_activeSessionKey);
    notifyListeners();
  }

  void _playSuccessFeedback() {
    if (_settings.soundOn) {
      SystemSound.play(SystemSoundType.click);
    }
    if (_settings.hapticOn) {
      HapticFeedback.selectionClick();
    }
  }

  void _playErrorFeedback() {
    if (_settings.soundOn) {
      SystemSound.play(SystemSoundType.alert);
    }
    if (_settings.hapticOn) {
      HapticFeedback.lightImpact();
    }
  }

  void _pushMessage(String value) {
    _message = value;
    _messageVersion += 1;
  }

  void _persistSettings() {
    _prefs.setString(_settingsKey, _settings.toStorage());
  }

  void _persistDailyProgress() {
    _prefs.setString(_dailyProgressKey, _dailyProgress.toStorage());
  }

  void _persistSession() {
    final current = _session;
    if (current == null) {
      _prefs.remove(_activeSessionKey);
      return;
    }
    _prefs.setString(_activeSessionKey, current.toStorage());
  }

  String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return '${normalized.year.toString().padLeft(4, '0')}-'
        '${normalized.month.toString().padLeft(2, '0')}-'
        '${normalized.day.toString().padLeft(2, '0')}';
  }
}
