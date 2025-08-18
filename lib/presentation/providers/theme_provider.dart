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
      // Saat tema Natal, warna primer akan diabaikan dan diganti warna merah khas Natal
      return AppTheme.getChristmasTheme(_darkTheme);
    }
    return AppTheme.getTheme(_primaryColor, _darkTheme);
  }

  /// Menyediakan data (ikon & tooltip) untuk tombol siklus tema di UI.
  Map<String, dynamic> get themeCycleData {
    if (!_isChristmasTheme && !_darkTheme) {
      return {
        'icon': Icons.wb_sunny_outlined,
        'tooltip': 'Ganti ke Tema Gelap',
      };
    } else if (!_isChristmasTheme && _darkTheme) {
      return {
        'icon': Icons.nightlight_round,
        'tooltip': 'Ganti ke Tema Natal (Terang)',
      };
    } else if (_isChristmasTheme && !_darkTheme) {
      return {
        'icon': Icons.celebration_outlined,
        'tooltip': 'Ganti ke Tema Natal (Gelap)',
      };
    } else {
      // _isChristmasTheme && _darkTheme
      return {'icon': Icons.celebration, 'tooltip': 'Kembali ke Tema Terang'};
    }
  }

  ThemeProvider() {
    _loadTheme();
  }

  set darkTheme(bool value) {
    _darkTheme = value;
    _prefsService.saveThemePreference(value);
    notifyListeners();
  }

  /// Mengganti tema ke status berikutnya dalam siklus.
  void cycleTheme() {
    if (!_isChristmasTheme && !_darkTheme) {
      // Dari Terang -> Gelap
      _darkTheme = true;
    } else if (!_isChristmasTheme && _darkTheme) {
      // Dari Gelap -> Natal Terang
      _darkTheme = false;
      _isChristmasTheme = true;
    } else if (_isChristmasTheme && !_darkTheme) {
      // Dari Natal Terang -> Natal Gelap
      _darkTheme = true;
    } else {
      // Dari Natal Gelap -> Terang
      _darkTheme = false;
      _isChristmasTheme = false;
    }
    // Simpan preferensi mode gelap untuk konsistensi
    _prefsService.saveThemePreference(_darkTheme);
    notifyListeners();
  }

  void setPrimaryColor(Color color) {
    _primaryColor = color;
    _prefsService.savePrimaryColor(color.value);
    _addRecentColor(color);
    notifyListeners();
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
