// lib/data/services/shared_preferences_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart'; // Pastikan package uuid ditambahkan
import '../models/api_key_model.dart';

class SharedPreferencesService {
  static const String _sortTypeKey = 'sort_type';
  static const String _sortAscendingKey = 'sort_ascending';
  static const String _filterTypeKey = 'filter_type';
  static const String _filterValueKey = 'filter_value';
  static const String _themeKey = 'theme_preference';
  static const String _primaryColorKey = 'primary_color';
  static const String _recentColorsKey = 'recent_colors';
  static const String _backupSortTypeKey = 'backup_sort_type';
  static const String _backupSortAscendingKey = 'backup_sort_ascending';
  static const String _apiDomainKey = 'api_domain';
  static const String _apiKeyKey = 'api_key';
  static const String _backgroundImageKey = 'background_image_path';
  static const String _dashboardItemScaleKey = 'dashboard_item_scale';

  // KUNCI BARU UNTUK FLO
  static const String _showFloatingCharacterKey = 'show_floating_character';

  // KUNCI BARU UNTUK MODEL GEMINI
  static const String _geminiModelKey = 'gemini_model';

  // Kunci lama (deprecated), digunakan untuk migrasi
  static const String _geminiApiKey_old = 'gemini_api_key';
  // Kunci baru untuk menyimpan list
  static const String _geminiApiKeys = 'gemini_api_keys_list';

  // --- KUNCI PENYIMPANAN UTAMA ---
  static const String _customStoragePathKey = 'custom_storage_path';
  static const String _customStoragePathKeyDebug = 'custom_storage_path_debug';

  // --- KUNCI PENYIMPANAN BACKUP ---
  static const String _customBackupPathKey = 'custom_backup_path';
  static const String _customBackupPathKeyDebug = 'custom_backup_path_debug';

  // --- KUNCI PENYIMPANAN DOWNLOAD ---
  static const String _customDownloadPathKey = 'custom_download_path';
  static const String _customDownloadPathKeyDebug =
      'custom_download_path_debug';

  // --- KUNCI SUMBER DATA PERPUSKU ---
  static const String _perpuskuDataPathKey = 'perpusku_data_path';
  static const String _perpuskuDataPathKeyDebug = 'perpusku_data_path_debug';

  // ==> FUNGSI BARU UNTUK MENYIMPAN DAN MEMUAT LIST API KEY <==
  Future<void> saveApiKeys(List<ApiKey> keys) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = encodeApiKeys(keys);
    await prefs.setString(_geminiApiKeys, encodedData);
  }

  Future<List<ApiKey>> loadApiKeys() async {
    final prefs = await SharedPreferences.getInstance();

    // Cek apakah data dengan format list baru sudah ada
    if (prefs.containsKey(_geminiApiKeys)) {
      final String? encodedData = prefs.getString(_geminiApiKeys);
      return decodeApiKeys(encodedData ?? '[]');
    }

    // Logika Migrasi: Cek apakah ada kunci tunggal yang lama
    if (prefs.containsKey(_geminiApiKey_old)) {
      final String? oldKey = prefs.getString(_geminiApiKey_old);
      if (oldKey != null && oldKey.isNotEmpty) {
        // Buat key baru dari data lama
        final migratedKey = ApiKey(
          id: const Uuid().v4(),
          name: 'Kunci Lama (Default)',
          key: oldKey,
          isActive: true,
        );
        final List<ApiKey> keys = [migratedKey];
        await saveApiKeys(keys); // Simpan dalam format list baru
        await prefs.remove(_geminiApiKey_old); // Hapus kunci lama
        return keys;
      }
    }

    return []; // Kembalikan list kosong jika tidak ada data
  }

  Future<void> saveGeminiModel(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiModelKey, modelId);
  }

  Future<String?> loadGeminiModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiModelKey);
  }

  // ==> TAMBAHKAN METODE BARU UNTUK PREFERENSI FLO <==
  Future<void> saveShowFloPreference(bool showFlo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showFloatingCharacterKey, showFlo);
  }

  Future<bool> loadShowFloPreference() async {
    final prefs = await SharedPreferences.getInstance();
    // Default-nya aktif
    return prefs.getBool(_showFloatingCharacterKey) ?? true;
  }

  Future<void> saveDashboardItemScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_dashboardItemScaleKey, scale);
  }

  Future<double> loadDashboardItemScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_dashboardItemScaleKey) ?? 1.0;
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
    final key = kDebugMode
        ? _customDownloadPathKeyDebug
        : _customDownloadPathKey;
    await prefs.setString(key, path);
  }

  Future<String?> loadCustomDownloadPath() async {
    final prefs = await SharedPreferences.getInstance();
    final key = kDebugMode
        ? _customDownloadPathKeyDebug
        : _customDownloadPathKey;
    return prefs.getString(key);
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
    final sortType = prefs.getString(_backupSortTypeKey) ?? 'date';
    final sortAscending = prefs.getBool(_backupSortAscendingKey) ?? false;
    return {'sortType': sortType, 'sortAscending': sortAscending};
  }

  Future<void> saveCustomBackupPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final key = kDebugMode ? _customBackupPathKeyDebug : _customBackupPathKey;
    await prefs.setString(key, path);
  }

  Future<String?> loadCustomBackupPath() async {
    final prefs = await SharedPreferences.getInstance();
    final key = kDebugMode ? _customBackupPathKeyDebug : _customBackupPathKey;
    return prefs.getString(key);
  }

  Future<void> savePerpuskuDataPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final key = kDebugMode ? _perpuskuDataPathKeyDebug : _perpuskuDataPathKey;
    await prefs.setString(key, path);
  }

  Future<String?> loadPerpuskuDataPath() async {
    final prefs = await SharedPreferences.getInstance();
    final key = kDebugMode ? _perpuskuDataPathKeyDebug : _perpuskuDataPathKey;
    return prefs.getString(key);
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
    final key = kDebugMode ? _customStoragePathKeyDebug : _customStoragePathKey;
    await prefs.setString(key, path);
  }

  Future<String?> loadCustomStoragePath() async {
    final prefs = await SharedPreferences.getInstance();
    final key = kDebugMode ? _customStoragePathKeyDebug : _customStoragePathKey;
    return prefs.getString(key);
  }
}
