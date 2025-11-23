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
  
  LanguageNotifier() : super(const Locale('en')) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final box = await Hive.openBox(_boxName);
    final languageCode = box.get(_languageKey, defaultValue: 'en') as String;
    state = Locale(languageCode);
  }

  Future<void> setLanguage(String languageCode) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_languageKey, languageCode);
    state = Locale(languageCode);
  }

  void toggleLanguage() {
    final newLang = state.languageCode == 'en' ? 'vi' : 'en';
    setLanguage(newLang);
  }
}
