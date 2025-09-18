// lib/features/settings/application/services/api_config_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfigService {
  final PathService _pathService = PathService();

  Future<File> get _configFile async {
    final basePath = await _pathService.contentsPath;
    return File(path.join(basePath, 'api_config.json'));
  }

  /// Memuat konfigurasi API dari file JSON.
  /// Termasuk logika migrasi satu kali dari SharedPreferences.
  Future<Map<String, String?>> loadConfig() async {
    try {
      final file = await _configFile;
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        if (jsonString.isNotEmpty) {
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          return {
            'domain': jsonData['domain'] as String?,
            'apiKey': jsonData['apiKey'] as String?,
          };
        }
      } else {
        // Logika Migrasi: Jika file JSON tidak ada, cek SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final oldDomain = prefs.getString('api_domain');
        final oldApiKey = prefs.getString('api_key');

        if (oldDomain != null && oldApiKey != null) {
          debugPrint(
            "Migrating API config from SharedPreferences to JSON file...",
          );
          final config = {'domain': oldDomain, 'apiKey': oldApiKey};
          await saveConfig(oldDomain, oldApiKey); // Simpan ke file JSON
          // Hapus data lama dari SharedPreferences setelah migrasi berhasil
          await prefs.remove('api_domain');
          await prefs.remove('api_key');
          return config;
        }
      }
    } catch (e) {
      debugPrint("Error loading API config: $e");
    }
    // Return default jika tidak ada data
    return {'domain': null, 'apiKey': null};
  }

  /// Menyimpan konfigurasi API ke file JSON.
  Future<void> saveConfig(String domain, String apiKey) async {
    final file = await _configFile;
    final configData = {'domain': domain, 'apiKey': apiKey};
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(configData));
  }
}
