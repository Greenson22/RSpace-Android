// lib/features/settings/application/theme_settings_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/core/theme/app_theme.dart';
import 'package:path/path.dart' as path;
import '../domain/models/theme_settings_model.dart';

class ThemeSettingsService {
  final PathService _pathService = PathService();

  Future<File> get _settingsFile async {
    final basePath = await _pathService.contentsPath;
    return File(path.join(basePath, 'theme_settings.json'));
  }

  Future<ThemeSettings> loadSettings() async {
    try {
      final file = await _settingsFile;
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        if (jsonString.isNotEmpty) {
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          return ThemeSettings.fromJson(jsonData);
        }
      }
    } catch (e) {
      debugPrint("Error loading theme settings, returning default: $e");
    }
    // Return default settings if file doesn't exist or is invalid
    return ThemeSettings(
      primaryColorValue: AppTheme.selectableColors.first.value,
    );
  }

  Future<void> saveSettings(ThemeSettings settings) async {
    final file = await _settingsFile;
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(settings.toJson()));
  }
}
