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
  static const String _customBackupPathKey = 'custom_backup_path';
  static const String _backupSortTypeKey = 'backup_sort_type';
  static const String _backupSortAscendingKey = 'backup_sort_ascending';
  static const String _customDownloadPathKey = 'custom_download_path';
  static const String _apiDomainKey = 'api_domain';
  static const String _apiKeyKey = 'api_key';
  // ==> KUNCI BARU UNTUK GAMBAR LATAR <==
  static const String _backgroundImageKey = 'background_image_path';

  // ==> FUNGSI BARU UNTUK GAMBAR LATAR <==
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
  // --- AKHIR PERUBAHAN ---

  Future<void> saveApiConfig(String domain, String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiDomainKey, domain);
    await prefs.setString(_apiKeyKey, apiKey);
  }

  Future<Map<String, String?>> loadApiConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final domain = prefs.getString(_apiDomainKey);
    final apiKey = prefs.getString(_apiKeyKey);
    return {'domain': domain, 'apiKey': apiKey};
  }

  Future<void> saveCustomDownloadPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customDownloadPathKey, path);
  }

  Future<String?> loadCustomDownloadPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customDownloadPathKey);
  }

  Future<void> saveBackupSortPreferences(
    String sortType,
    bool sortAscending,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backupSortTypeKey, sortType);
    await prefs.setBool(_backupSortAscendingKey, sortAscending);
  }

  Future<Map<String, dynamic>> loadBackupSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final sortType =
        prefs.getString(_backupSortTypeKey) ?? 'date'; // Default by date
    final sortAscending =
        prefs.getBool(_backupSortAscendingKey) ?? false; // Default descending
    return {'sortType': sortType, 'sortAscending': sortAscending};
  }

  Future<void> saveCustomBackupPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customBackupPathKey, path);
  }

  Future<String?> loadCustomBackupPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_customBackupPathKey);
  }

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
