import 'dart:convert';

class DailyProgress {
  DailyProgress({
    this.streak = 0,
    this.lastCompletedDate,
    Set<String>? completedDates,
  }) : completedDates = completedDates ?? <String>{};

  final int streak;
  final String? lastCompletedDate;
  final Set<String> completedDates;

  bool isCompleted(String dateKey) => completedDates.contains(dateKey);

  DailyProgress registerCompletion(String dateKey, String yesterdayKey) {
    if (completedDates.contains(dateKey)) {
      return this;
    }

    final nextCompletedDates = Set<String>.from(completedDates)..add(dateKey);
    final nextStreak = lastCompletedDate == yesterdayKey ? streak + 1 : 1;

    return DailyProgress(
      streak: nextStreak,
      lastCompletedDate: dateKey,
      completedDates: nextCompletedDates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'streak': streak,
      'lastCompletedDate': lastCompletedDate,
      'completedDates': completedDates.toList(),
    };
  }

  String toStorage() => jsonEncode(toJson());

  static DailyProgress fromStorage(String? raw) {
    if (raw == null || raw.isEmpty) {
      return DailyProgress();
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return DailyProgress(
      streak: json['streak'] as int? ?? 0,
      lastCompletedDate: json['lastCompletedDate'] as String?,
      completedDates: ((json['completedDates'] as List<dynamic>?) ?? const [])
          .cast<String>()
          .toSet(),
    );
  }
}
