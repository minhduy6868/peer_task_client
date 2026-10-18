import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Language provider
final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<Locale> {
  static const String _boxName = 'settings';
  static const String _languageKey = 'language';
  
  LanguageNotifier() : super(_resolveInitialLocale()) {
    _loadLanguage();
  }

  /// Synchronously determines the initial locale:
  /// 1. Saved choice in Hive (if box is already open)
  /// 2. Browser/system locale if Vietnamese
  /// 3. Fallback to English
  static Locale _resolveInitialLocale() {
    if (Hive.isBoxOpen(_boxName)) {
      final box = Hive.box(_boxName);
      final saved = box.get(_languageKey) as String?;
      if (saved == 'vi' || saved == 'en') {
        return Locale(saved!);
      }
    }
    return _resolveSystemLocale();
  }

  static Locale _resolveSystemLocale() {
    try {
      final locales = WidgetsBinding.instance.platformDispatcher.locales;
      for (final loc in locales) {
        if (loc.languageCode.toLowerCase() == 'vi') {
          return const Locale('vi');
        }
      }
      final sysLocale = WidgetsBinding.instance.platformDispatcher.locale;
      if (sysLocale.languageCode.toLowerCase() == 'vi') {
        return const Locale('vi');
      }
    } catch (_) {}
    return const Locale('en');
  }

  Future<void> _loadLanguage() async {
    try {
      final box = Hive.isBoxOpen(_boxName)
          ? Hive.box(_boxName)
          : await Hive.openBox(_boxName);
      final saved = box.get(_languageKey) as String?;
      if (saved == 'vi' || saved == 'en') {
        state = Locale(saved!);
      } else {
        state = _resolveSystemLocale();
      }
    } catch (e) {
      debugPrint('Error loading language: $e');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    try {
      final box = Hive.isBoxOpen(_boxName)
          ? Hive.box(_boxName)
          : await Hive.openBox(_boxName);
      await box.put(_languageKey, languageCode);
      state = Locale(languageCode);
    } catch (e) {
      debugPrint('Error saving language: $e');
      state = Locale(languageCode);
    }
  }

  void toggleLanguage() {
    final newLang = state.languageCode == 'en' ? 'vi' : 'en';
    setLanguage(newLang);
  }
}
