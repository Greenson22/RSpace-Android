// lib/features/settings/application/services/dashboard_settings_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardSettingsService {
  final PathService _pathService = PathService();

  // Kunci lama dari SharedPreferences untuk migrasi
  static const String _oldExcludedSubjectsKey =
      'excluded_subjects_for_progress';
  static const String _oldExcludedTasksKey = 'excluded_task_categories';

  Future<File> get _settingsFile async {
    final basePath = await _pathService.contentsPath;
    return File(path.join(basePath, 'dashboard_settings.json'));
  }

  /// Memuat setelan pengecualian dari file JSON.
  /// Termasuk logika migrasi satu kali dari SharedPreferences.
  Future<Map<String, Set<String>>> loadSettings() async {
    try {
      final file = await _settingsFile;
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        if (jsonString.isNotEmpty) {
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          return {
            'excludedSubjects': Set<String>.from(
              jsonData['excluded_subjects_for_progress'] as List<dynamic>? ??
                  [],
            ),
            'excludedTaskCategories': Set<String>.from(
              jsonData['excluded_task_categories'] as List<dynamic>? ?? [],
            ),
          };
        }
      } else {
        // Logika Migrasi: Jika file JSON tidak ada, cek SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final oldSubjects = prefs.getStringList(_oldExcludedSubjectsKey);
        final oldTasks = prefs.getStringList(_oldExcludedTasksKey);

        if (oldSubjects != null || oldTasks != null) {
          debugPrint("Migrating dashboard settings from SharedPreferences...");
          final settings = {
            'excludedSubjects': oldSubjects?.toSet() ?? <String>{},
            'excludedTaskCategories': oldTasks?.toSet() ?? <String>{},
          };
          // Simpan ke file JSON baru
          await saveSettings(
            excludedSubjects: settings['excludedSubjects']!,
            excludedTaskCategories: settings['excludedTaskCategories']!,
          );
          // Hapus data lama setelah migrasi
          await prefs.remove(_oldExcludedSubjectsKey);
          await prefs.remove(_oldExcludedTasksKey);
          return settings;
        }
      }
    } catch (e) {
      debugPrint("Error loading dashboard settings: $e");
    }
    // Return default jika tidak ada data
    return {
      'excludedSubjects': <String>{},
      'excludedTaskCategories': <String>{},
    };
  }

  /// Menyimpan setelan pengecualian ke file JSON.
  Future<void> saveSettings({
    required Set<String> excludedSubjects,
    required Set<String> excludedTaskCategories,
  }) async {
    final file = await _settingsFile;
    final settingsData = {
      'excluded_subjects_for_progress': excludedSubjects.toList(),
      'excluded_task_categories': excludedTaskCategories.toList(),
    };
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(settingsData));
  }
}
