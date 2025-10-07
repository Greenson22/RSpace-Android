// lib/features/settings/application/services/api_config_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfigService {
  final PathService _pathService = PathService();

  // ==> FUNGSI INI DIPERBARUI MENGGUNAKAN GETTER BARU DARI PATHSERVICE <==
  Future<File> get _configFile async {
    final configFilePath = await _pathService.apiConfigPath;
    return File(configFilePath);
  }

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
        final prefs = await SharedPreferences.getInstance();
        final oldDomain = prefs.getString('api_domain');
        final oldApiKey = prefs.getString('api_key');

        if (oldDomain != null && oldApiKey != null) {
          debugPrint(
            "Migrating API config from SharedPreferences to JSON file...",
          );
          final config = {'domain': oldDomain, 'apiKey': oldApiKey};
          await saveConfig(oldDomain, oldApiKey);
          await prefs.remove('api_domain');
          await prefs.remove('api_key');
          return config;
        }
      }
    } catch (e) {
      debugPrint("Error loading API config: $e");
    }
    return {'domain': null, 'apiKey': null};
  }

  Future<void> saveConfig(String domain, String apiKey) async {
    final file = await _configFile;
    final configData = {'domain': domain, 'apiKey': apiKey};
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(configData));
  }
}
