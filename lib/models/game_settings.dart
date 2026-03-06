import 'dart:convert';

import 'app_enums.dart';

class GameSettings {
  const GameSettings({
    this.errorMode = ErrorMode.instant,
    this.soundOn = true,
    this.hapticOn = true,
  });

  final ErrorMode errorMode;
  final bool soundOn;
  final bool hapticOn;

  GameSettings copyWith({
    ErrorMode? errorMode,
    bool? soundOn,
    bool? hapticOn,
  }) {
    return GameSettings(
      errorMode: errorMode ?? this.errorMode,
      soundOn: soundOn ?? this.soundOn,
      hapticOn: hapticOn ?? this.hapticOn,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'errorMode': errorMode.name,
      'soundOn': soundOn,
      'hapticOn': hapticOn,
    };
  }

  String toStorage() => jsonEncode(toJson());

  static GameSettings fromStorage(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const GameSettings();
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return GameSettings(
      errorMode: ErrorMode.values.firstWhere(
        (mode) => mode.name == json['errorMode'],
        orElse: () => ErrorMode.instant,
      ),
      soundOn: json['soundOn'] as bool? ?? true,
      hapticOn: json['hapticOn'] as bool? ?? true,
    );
  }
}
