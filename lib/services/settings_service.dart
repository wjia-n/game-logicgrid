import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/grid_themes.dart';

/// Persisted settings + stats for Logic Grid. Survives app restarts.
///
/// The detective profile (name + stats) is stored as ONE JSON string —
/// NEVER setStringList (Android stores StringLists as an unordered
/// StringSet, which scrambles order). Legacy individual keys are migrated
/// once and then removed.
class DetectiveSettings extends ChangeNotifier {
  static const _kMusic = 'logicgrid_music_on';
  static const _kSfx = 'logicgrid_sfx_on';
  static const _kVolume = 'logicgrid_volume';
  static const _kTheme = 'logicgrid_theme_id';
  static const _kMarks = 'logicgrid_mark_style';
  static const _kIsPro = 'logicgrid_is_pro';

  /// Order-safe profile storage: ONE JSON string via setString.
  /// NEVER setStringList here — Android persists StringLists as an unordered
  /// StringSet, which scrambles order across restarts.
  static const _kProfileJson = 'logicgrid_player_names_json';

  /// Legacy keys (migrated once, then deleted).
  static const _kLegacyJson = 'logicgrid_profile_json';
  static const _kLegacyName = 'logicgrid_detective_name';
  static const _kLegacySolved = 'logicgrid_solved_total';

  static const _kCustomPrefix = 'logicgrid_custom_';

  static const defaultName = 'Detective';

  /// UI-safe name: never shows an empty string while the user is typing.
  String get displayName =>
      detectiveName.trim().isEmpty ? defaultName : detectiveName;

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  String themeId = 'classic';
  int markStyle = 0;
  bool isPro = true; // everything unlocked — no Pro version

  // --- Profile (single JSON) ---
  String detectiveName = defaultName;
  int solvedEasy = 0;
  int solvedMedium = 0;
  int solvedHard = 0;
  int solvedDaily = 0;
  int bestScoreEasy = 0;
  int bestScoreMedium = 0;
  int bestScoreHard = 0;
  int dailyStreak = 0;
  String lastDaily = ''; // yyyy-MM-dd of last completed daily

  int get totalSolved => solvedEasy + solvedMedium + solvedHard + solvedDaily;

  /// Custom theme colors (ARGB ints). Defaults mirror the classic desk.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'deskDark': 0xFF3B2416,
    'deskMid': 0xFF5C3A21,
    'deskDeep': 0xFF241309,
    'paper': 0xFFF1E6C8,
    'paperDark': 0xFFE0CDA0,
    'ink': 0xFF2E2118,
    'accent': 0xFFC9A227,
    'accentLight': 0xFFE8CE7A,
    'accentDark': 0xFF8A6D1A,
    'stamp': 0xFFA31621,
  };

  DetectiveThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return DetectiveThemeDef(
      id: 'custom',
      name: 'My Creation',
      deskDark: c('deskDark'),
      deskMid: c('deskMid'),
      deskDeep: c('deskDeep'),
      paper: c('paper'),
      paperDark: c('paperDark'),
      ink: c('ink'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      accentDark: c('accentDark'),
      stamp: c('stamp'),
    );
  }

  DetectiveThemeDef get theme =>
      DetectiveThemes.byId(themeId, custom: customTheme);

  SharedPreferences? _prefs;

  Map<String, dynamic> _profileToJson() => {
        'name': detectiveName,
        'solvedEasy': solvedEasy,
        'solvedMedium': solvedMedium,
        'solvedHard': solvedHard,
        'solvedDaily': solvedDaily,
        'bestScoreEasy': bestScoreEasy,
        'bestScoreMedium': bestScoreMedium,
        'bestScoreHard': bestScoreHard,
        'dailyStreak': dailyStreak,
        'lastDaily': lastDaily,
      };

  void _profileFromJson(Map<String, dynamic> j) {
    int asInt(String k) => (j[k] is int) ? j[k] as int : 0;
    final rawName = j['name'];
    detectiveName = (rawName is String && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : defaultName;
    solvedEasy = asInt('solvedEasy');
    solvedMedium = asInt('solvedMedium');
    solvedHard = asInt('solvedHard');
    solvedDaily = asInt('solvedDaily');
    bestScoreEasy = asInt('bestScoreEasy');
    bestScoreMedium = asInt('bestScoreMedium');
    bestScoreHard = asInt('bestScoreHard');
    dailyStreak = asInt('dailyStreak');
    final rawDay = j['lastDaily'];
    lastDaily = rawDay is String ? rawDay : '';
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;

    // Profile: prefer the order-safe JSON key; migrate legacy keys once.
    var raw = p.getString(_kProfileJson);
    raw ??= p.getString(_kLegacyJson);
    if (raw != null) {
      try {
        final d = jsonDecode(raw);
        if (d is Map<String, dynamic>) _profileFromJson(d);
      } catch (_) {}
    } else {
      final legacyName = p.getString(_kLegacyName);
      if (legacyName != null && legacyName.trim().isNotEmpty) {
        detectiveName = legacyName.trim();
      }
      solvedEasy = p.getInt(_kLegacySolved) ?? 0;
    }
    // Drop legacy keys for good after migration.
    await p.remove(_kLegacyJson);
    await p.remove(_kLegacyName);
    await p.remove(_kLegacySolved);

    themeId = p.getString(_kTheme) ?? 'classic';
    markStyle = (p.getInt(_kMarks) ?? 0).clamp(0, 7);
    isPro = true; // everything unlocked
    for (final k in _defaultCustomColors.keys) {
      customColors[k] =
          p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setString(_kProfileJson, jsonEncode(_profileToJson()));
    await p.setString(_kTheme, themeId);
    await p.setInt(_kMarks, markStyle);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || DetectiveThemes.isProTheme(themeId)) {
      themeId = 'classic';
      changed = true;
    }
    if (MarkStyles.isPro(markStyle)) {
      markStyle = 0;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  /// Live-save every keystroke (untrimmed so trailing spaces survive while
  /// typing); committed (trimmed) on focus loss / keyboard-done.
  Future<void> setDetectiveNameLive(String raw) async {
    detectiveName = raw;
    notifyListeners();
    await _save();
  }

  /// Commit the detective name: trims, falls back to the default on empty.
  Future<void> setDetectiveName(String name) async {
    final clean = name.trim();
    detectiveName = clean.isEmpty ? defaultName : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || DetectiveThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setMarkStyle(int v) async {
    v = v.clamp(0, 7);
    if (!isPro && MarkStyles.isPro(v)) return;
    markStyle = v;
    notifyListeners();
    await _save();
  }

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Record a solved case. [difficultyId] is 'easy'/'medium'/'hard'/'daily'.
  /// Updates the daily streak when a daily case is completed.
  Future<void> recordSolved({
    required String difficultyId,
    required int score,
  }) async {
    switch (difficultyId) {
      case 'easy':
        solvedEasy++;
        if (score > bestScoreEasy) bestScoreEasy = score;
      case 'medium':
        solvedMedium++;
        if (score > bestScoreMedium) bestScoreMedium = score;
      case 'hard':
        solvedHard++;
        if (score > bestScoreHard) bestScoreHard = score;
      case 'daily':
        solvedDaily++;
        final today = dayKey(DateTime.now());
        if (lastDaily != today) {
          // Streak continues if yesterday was the last daily, else restarts.
          final yesterday = dayKey(
              DateTime.now().subtract(const Duration(days: 1)));
          dailyStreak = (lastDaily == yesterday) ? dailyStreak + 1 : 1;
          lastDaily = today;
        }
    }
    notifyListeners();
    await _save();
  }

  bool get dailyDoneToday => lastDaily == dayKey(DateTime.now());
}
