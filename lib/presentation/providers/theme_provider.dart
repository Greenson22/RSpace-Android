// lib/presentation/providers/theme_provider.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
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

  // ==> STATE BARU UNTUK GAMBAR LATAR <==
  String? _backgroundImagePath;
  String? get backgroundImagePath => _backgroundImagePath;

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

  // ==> FUNGSI BARU UNTUK MENGATUR GAMBAR LATAR <==
  Future<void> setBackgroundImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      _backgroundImagePath = result.files.single.path;
      await _prefsService.saveBackgroundImagePath(_backgroundImagePath!);
      notifyListeners();
    }
  }

  // ==> FUNGSI BARU UNTUK MENGHAPUS GAMBAR LATAR <==
  Future<void> clearBackgroundImage() async {
    _backgroundImagePath = null;
    await _prefsService.clearBackgroundImagePath();
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

    // ==> MEMUAT PATH GAMBAR LATAR SAAT INISIALISASI <==
    _backgroundImagePath = await _prefsService.loadBackgroundImagePath();

    notifyListeners();
  }
}
