import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageController extends ChangeNotifier {
  Locale _locale = const Locale('en'); // اللغة الافتراضية

  Locale get locale => _locale;

  // 1. دالة لجلب اللغة المحفوظة من الذاكرة
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_language') ?? 'en';
    _locale = Locale(savedLang);
    notifyListeners();
  }

  // 2. دالة لتغيير اللغة وحفظها
  Future<void> changeLanguage(String langCode) async {
    if (_locale.languageCode == langCode) return;

    _locale = Locale(langCode);
    notifyListeners(); // تحديث الشاشة

    // حفظ اللغة في الذاكرة
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', langCode);
  }
}

final languageController = LanguageController();