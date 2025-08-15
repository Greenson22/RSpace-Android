// lib/data/services/shared_preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static const String _sortTypeKey = 'sort_type';
  static const String _sortAscendingKey = 'sort_ascending';
  static const String _filterTypeKey = 'filter_type';
  static const String _filterValueKey = 'filter_value';
  static const String _themeKey = 'theme_preference';
  static const String _customStoragePathKey = 'custom_storage_path';
  static const String _primaryColorKey = 'primary_color';
  static const String _recentColorsKey = 'recent_colors';
  static const String _perpuskuDataPathKey = 'perpusku_data_path';
  // ==> KUNCI BARU UNTUK LOKASI BACKUP <==
  static const String _customBackupPathKey = 'custom_backup_path';

  // ==> FUNGSI BARU UNTUK MENYIMPAN & MEMUAT PATH BACKUP <==
  Future<void> saveCustomBackupPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customBackupPathKey, path);
  }

  Future<String?> loadCustomBackupPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customBackupPathKey);
  }
  // --- AKHIR PERUBAHAN ---

  Future<void> savePerpuskuDataPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_perpuskuDataPathKey, path);
  }

  Future<String?> loadPerpuskuDataPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_perpuskuDataPathKey);
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

  Future<void> savePrimaryColor(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_primaryColorKey, colorValue);
  }

  Future<int?> loadPrimaryColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_primaryColorKey);
  }

  Future<void> saveThemePreference(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDarkMode);
  }

  Future<bool> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false;
  }

  Future<void> saveSortPreferences(String sortType, bool sortAscending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortTypeKey, sortType);
    await prefs.setBool(_sortAscendingKey, sortAscending);
  }

  Future<Map<String, dynamic>> loadSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final sortType = prefs.getString(_sortTypeKey) ?? 'date';
    final sortAscending = prefs.getBool(_sortAscendingKey) ?? true;
    return {'sortType': sortType, 'sortAscending': sortAscending};
  }

  Future<void> saveFilterPreference(
    String? filterType,
    String? filterValue,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (filterType != null) {
      await prefs.setString(_filterTypeKey, filterType);
    } else {
      await prefs.remove(_filterTypeKey);
    }
    if (filterValue != null) {
      await prefs.setString(_filterValueKey, filterValue);
    } else {
      await prefs.remove(_filterValueKey);
    }
  }

  Future<Map<String, String?>> loadFilterPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final filterType = prefs.getString(_filterTypeKey);
    final filterValue = prefs.getString(_filterValueKey);
    return {'filterType': filterType, 'filterValue': filterValue};
  }

  Future<void> saveCustomStoragePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customStoragePathKey, path);
  }

  Future<String?> loadCustomStoragePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customStoragePathKey);
  }
}
