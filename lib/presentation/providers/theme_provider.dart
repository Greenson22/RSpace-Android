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

  // ==> STATE BARU UNTUK RIWAYAT WARNA <==
  List<Color> _recentColors = [];
  List<Color> get recentColors => _recentColors;

  ThemeData get currentTheme => AppTheme.getTheme(_primaryColor, _darkTheme);

  ThemeProvider() {
    _loadTheme();
  }

  set darkTheme(bool value) {
    _darkTheme = value;
    _prefsService.saveThemePreference(value);
    notifyListeners();
  }

  // ==> FUNGSI SET WARNA DIPERBARUI <==
  void setPrimaryColor(Color color) {
    _primaryColor = color;
    _prefsService.savePrimaryColor(color.value);
    _addRecentColor(color); // Panggil fungsi untuk menambahkan ke riwayat
    notifyListeners();
  }

  // ==> FUNGSI BARU UNTUK MENGELOLA RIWAYAT WARNA <==
  void _addRecentColor(Color color) {
    // Hapus jika warna sudah ada untuk dipindahkan ke depan
    _recentColors.remove(color);
    // Tambahkan warna baru di posisi pertama
    _recentColors.insert(0, color);
    // Batasi jumlah riwayat, misalnya 6 warna terakhir
    if (_recentColors.length > 6) {
      _recentColors = _recentColors.sublist(0, 6);
    }
    // Simpan ke SharedPreferences
    final colorValues = _recentColors.map((c) => c.value).toList();
    _prefsService.saveRecentColors(colorValues);
  }

  Future<void> _loadTheme() async {
    _darkTheme = await _prefsService.loadThemePreference();
    final colorValue = await _prefsService.loadPrimaryColor();
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }

    // ==> MEMUAT RIWAYAT WARNA SAAT INISIALISASI <==
    final recentColorValues = await _prefsService.loadRecentColors();
    _recentColors = recentColorValues.map((v) => Color(v)).toList();

    notifyListeners();
  }
}
