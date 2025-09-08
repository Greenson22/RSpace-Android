// lib/data/services/shared_preferences/path_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PathService {
  static const String _customStoragePathKey = 'custom_storage_path';
  static const String _customStoragePathKeyDebug = 'custom_storage_path_debug';
  static const String _customBackupPathKey = 'custom_backup_path';
  static const String _customBackupPathKeyDebug = 'custom_backup_path_debug';
  static const String _customDownloadPathKey = 'custom_download_path';
  static const String _customDownloadPathKeyDebug =
      'custom_download_path_debug';
  static const String _perpuskuDataPathKey = 'perpusku_data_path';
  static const String _perpuskuDataPathKeyDebug = 'perpusku_data_path_debug';

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
}
