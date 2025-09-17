// lib/features/settings/application/services/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  // ==> KUNCI BARU UNTUK LAYOUT MY TASKS
  static const String _myTasksLayoutKey = 'my_tasks_grid_view';

  // ==> FUNGSI BARU UNTUK LAYOUT MY TASKS <==
  Future<void> saveMyTasksLayoutPreference(bool isGridView) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_myTasksLayoutKey, isGridView);
  }

  Future<bool> loadMyTasksLayoutPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_myTasksLayoutKey) ?? false; // Defaultnya list view
  }
}
