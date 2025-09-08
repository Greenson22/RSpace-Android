// lib/data/services/shared_preferences/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _themeKey = 'theme_preference';
  static const String _primaryColorKey = 'primary_color';
  static const String _recentColorsKey = 'recent_colors';
  static const String _backgroundImageKey = 'background_image_path';
  static const String _dashboardItemScaleKey = 'dashboard_item_scale';
  static const String _showFloatingCharacterKey = 'show_floating_character';
  // ==> KUNCI BARU UNTUK TEMA NATAL <==
  static const String _christmasThemeKey = 'christmas_theme_preference';

  Future<void> saveThemePreference(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDarkMode);
  }

  Future<bool> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }

  // ==> FUNGSI BARU UNTUK MENYIMPAN TEMA NATAL <==
  Future<void> saveChristmasThemePreference(bool isChristmas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_christmasThemeKey, isChristmas);
  }

  // ==> FUNGSI BARU UNTUK MEMUAT TEMA NATAL <==
  Future<bool> loadChristmasThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_christmasThemeKey) ?? false;
  }

  Future<void> savePrimaryColor(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_primaryColorKey, colorValue);
  }

  Future<int?> loadPrimaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_primaryColorKey);
  }

  Future<void> saveRecentColors(List<int> colorValues) async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = colorValues.map((v) => v.toString()).toList();
    await prefs.setStringList(_recentColorsKey, stringList);
  }

  Future<List<int>> loadRecentColors() async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = prefs.getStringList(_recentColorsKey) ?? [];
    return stringList.map((s) => int.parse(s)).toList();
  }

  Future<void> saveBackgroundImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundImageKey, path);
  }

  Future<String?> loadBackgroundImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backgroundImageKey);
  }

  Future<void> clearBackgroundImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backgroundImageKey);
  }

  Future<void> saveDashboardItemScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_dashboardItemScaleKey, scale);
  }

  Future<double> loadDashboardItemScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_dashboardItemScaleKey) ?? 1.0;
  }

  Future<void> saveShowFloPreference(bool showFlo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showFloatingCharacterKey, showFlo);
  }

  Future<bool> loadShowFloPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showFloatingCharacterKey) ?? true;
  }
}
