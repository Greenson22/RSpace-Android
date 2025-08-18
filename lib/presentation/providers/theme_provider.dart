// lib/presentation/providers/theme_provider.dart
import 'package:flutter/material.dart';
import '../../data/services/shared_preferences_service.dart';
import '../theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  final SharedPreferencesService _prefsService = SharedPreferencesService();

  bool _darkTheme = false;
  bool get darkTheme => _darkTheme;

  Color _primaryColor = AppTheme.selectableColors.first;
  Color get primaryColor => _primaryColor;

  List<Color> _recentColors = [];
  List<Color> get recentColors => _recentColors;

  bool _isChristmasTheme = false;
  bool get isChristmasTheme => _isChristmasTheme;

  ThemeData get currentTheme {
    if (_isChristmasTheme) {
      return AppTheme.getChristmasTheme(_darkTheme);
    }
    return AppTheme.getTheme(_primaryColor, _darkTheme);
  }

  ThemeProvider() {
    _loadTheme();
  }

  /// Memperbarui beberapa properti tema sekaligus dan memberitahu pendengar.
  void updateTheme({bool? isDark, bool? isChristmas, Color? color}) {
    bool needsNotify = false;

    if (isDark != null && _darkTheme != isDark) {
      _darkTheme = isDark;
      _prefsService.saveThemePreference(isDark);
      needsNotify = true;
    }
    if (isChristmas != null && _isChristmasTheme != isChristmas) {
      _isChristmasTheme = isChristmas;
      // Tema Natal bersifat sementara dan tidak disimpan
      needsNotify = true;
    }
    if (color != null && _primaryColor != color) {
      _primaryColor = color;
      _prefsService.savePrimaryColor(color.value);
      _addRecentColor(color);
      needsNotify = true;
    }

    if (needsNotify) {
      notifyListeners();
    }
  }

  void _addRecentColor(Color color) {
    _recentColors.remove(color);
    _recentColors.insert(0, color);
    if (_recentColors.length > 6) {
      _recentColors = _recentColors.sublist(0, 6);
    }
    final colorValues = _recentColors.map((c) => c.value).toList();
    _prefsService.saveRecentColors(colorValues);
  }

  Future<void> _loadTheme() async {
    _darkTheme = await _prefsService.loadThemePreference();
    final colorValue = await _prefsService.loadPrimaryColor();
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }

    final recentColorValues = await _prefsService.loadRecentColors();
    _recentColors = recentColorValues.map((v) => Color(v)).toList();

    notifyListeners();
  }
}
