import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _boxName = 'settings';
  static const String _themeKey = 'theme_mode';

  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme().catchError((_) {});
  }

  Future<void> _loadTheme() async {
    await Future<void>.delayed(Duration.zero);
    try {
      final box = await Hive.openBox(_boxName);
      final savedMode = box.get(_themeKey, defaultValue: 'system') as String;
      state = _stringToMode(savedMode);
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_themeKey, _modeToString(mode));
    } catch (_) {}
  }

  static ThemeMode _stringToMode(String str) {
    switch (str) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _modeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}
