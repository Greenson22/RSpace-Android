// lib/presentation/providers/theme_provider.dart
import 'package:flutter/material.dart';
import '../../data/services/shared_preferences_service.dart';
import '../theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  final SharedPreferencesService _prefsService = SharedPreferencesService();

  bool _darkTheme = false;
  bool get darkTheme => _darkTheme;

  // ==> STATE BARU UNTUK WARNA PRIMER <==
  Color _primaryColor = AppTheme.selectableColors.first; // Warna default
  Color get primaryColor => _primaryColor;

  // ==> GETTER BARU UNTUK MENDAPATKAN TEMA SAAT INI <==
  ThemeData get currentTheme => AppTheme.getTheme(_primaryColor, _darkTheme);

  ThemeProvider() {
    _loadTheme();
  }

  set darkTheme(bool value) {
    _darkTheme = value;
    _prefsService.saveThemePreference(value);
    notifyListeners();
  }

  // ==> FUNGSI BARU UNTUK MENGGANTI WARNA PRIMER <==
  void setPrimaryColor(Color color) {
    _primaryColor = color;
    _prefsService.savePrimaryColor(color.value);
    notifyListeners();
  }

  // ==> MEMUAT PREFERENSI WARNA DAN TEMA <==
  Future<void> _loadTheme() async {
    _darkTheme = await _prefsService.loadThemePreference();
    final colorValue = await _prefsService.loadPrimaryColor();
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }
    notifyListeners();
  }
}
