// lib/features/settings/application/services/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _themeKey = 'theme_preference';
  static const String _primaryColorKey = 'primary_color';
  static const String _recentColorsKey = 'recent_colors';
  static const String _backgroundImageKey = 'background_image_path';
  static const String _dashboardItemScaleKey = 'dashboard_item_scale';
  static const String _showFloatingCharacterKey = 'show_floating_character';
  static const String _christmasThemeKey = 'christmas_theme_preference';
  static const String _showQuickFabKey = 'show_quick_fab';
  static const String _quickFabIconKey = 'quick_fab_icon';
  // ==> 1. TAMBAHKAN KUNCI BARU UNTUK OPASITAS
  static const String _quickFabBgOpacityKey = 'quick_fab_bg_opacity';
  static const String _quickFabOverallOpacityKey = 'quick_fab_overall_opacity';

  Future<void> saveThemePreference(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDarkMode);
  }

  Future<bool> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }

  Future<void> saveChristmasThemePreference(bool isChristmas) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_christmasThemeKey, isChristmas);
  }

  Future<bool> loadChristmasThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_christmasThemeKey) ?? false;
  }

  Future<void> saveShowQuickFabPreference(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showQuickFabKey, show);
  }

  Future<bool> loadShowQuickFabPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showQuickFabKey) ?? true; // Defaultnya tampil
  }

  Future<void> saveShowQuickFabIconPreference(String icon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quickFabIconKey, icon);
  }

  Future<String> loadShowQuickFabIconPreference() async {
    final prefs = await SharedPreferences.getInstance();
    // Default ikon adalah '➕'
    return prefs.getString(_quickFabIconKey) ?? '➕';
  }

  // ==> 2. TAMBAHKAN FUNGSI BARU UNTUK MENYIMPAN & MEMUAT OPASITAS
  Future<void> saveQuickFabBgOpacity(double opacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_quickFabBgOpacityKey, opacity);
  }

  Future<double> loadQuickFabBgOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_quickFabBgOpacityKey) ?? 1.0; // Default 100%
  }

  Future<void> saveQuickFabOverallOpacity(double opacity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_quickFabOverallOpacityKey, opacity);
  }

  Future<double> loadQuickFabOverallOpacity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_quickFabOverallOpacityKey) ?? 1.0; // Default 100%
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
