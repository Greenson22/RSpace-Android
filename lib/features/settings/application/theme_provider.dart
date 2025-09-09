// lib/features/settings/application/theme_provider.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';

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

  String? _backgroundImagePath;
  String? get backgroundImagePath => _backgroundImagePath;

  double _dashboardItemScale = 1.0;
  double get dashboardItemScale => _dashboardItemScale;

  // State untuk Flo
  bool _showFloatingCharacter = true;
  bool get showFloatingCharacter => _showFloatingCharacter;

  // State untuk FAB Cepat
  bool _showQuickFab = true;
  bool get showQuickFab => _showQuickFab;

  // ==> 1. TAMBAHKAN STATE BARU UNTUK IKON FAB
  String _quickFabIcon = '➕';
  String get quickFabIcon => _quickFabIcon;

  ThemeData get currentTheme {
    if (_isChristmasTheme) {
      return AppTheme.getChristmasTheme(_darkTheme);
    }
    return AppTheme.getTheme(_primaryColor, _darkTheme);
  }

  ThemeProvider() {
    _loadTheme();
  }

  void updateTheme({
    bool? isDark,
    bool? isChristmas,
    Color? color,
    double? dashboardScale,
  }) {
    bool needsNotify = false;

    if (isDark != null && _darkTheme != isDark) {
      _darkTheme = isDark;
      _prefsService.saveThemePreference(isDark);
      needsNotify = true;
    }
    if (isChristmas != null && _isChristmasTheme != isChristmas) {
      _isChristmasTheme = isChristmas;
      needsNotify = true;
    }
    if (color != null && _primaryColor != color) {
      _primaryColor = color;
      _prefsService.savePrimaryColor(color.value);
      _addRecentColor(color);
      needsNotify = true;
    }
    if (dashboardScale != null && _dashboardItemScale != dashboardScale) {
      _dashboardItemScale = dashboardScale;
      _prefsService.saveDashboardItemScale(dashboardScale);
      needsNotify = true;
    }

    if (needsNotify) {
      notifyListeners();
    }
  }

  void toggleFloatingCharacter() async {
    _showFloatingCharacter = !_showFloatingCharacter;
    await _prefsService.saveShowFloPreference(_showFloatingCharacter);
    notifyListeners();
  }

  // ==> 2. BUAT FUNGSI BARU UNTUK MENGUPDATE PENGATURAN FAB
  Future<void> updateQuickFabSettings({bool? show, String? icon}) async {
    bool needsNotify = false;
    if (show != null && _showQuickFab != show) {
      _showQuickFab = show;
      await _prefsService.saveShowQuickFabPreference(_showQuickFab);
      needsNotify = true;
    }
    if (icon != null && _quickFabIcon != icon) {
      _quickFabIcon = icon;
      await _prefsService.saveShowQuickFabIconPreference(_quickFabIcon);
      needsNotify = true;
    }
    if (needsNotify) {
      notifyListeners();
    }
  }

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

  Future<void> clearBackgroundImagePath() async {
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
    _backgroundImagePath = await _prefsService.loadBackgroundImagePath();

    _dashboardItemScale = await _prefsService.loadDashboardItemScale();

    _showFloatingCharacter = await _prefsService.loadShowFloPreference();

    _showQuickFab = await _prefsService.loadShowQuickFabPreference();

    // ==> 3. MUAT IKON FAB SAAT APLIKASI DIMULAI
    _quickFabIcon = await _prefsService.loadShowQuickFabIconPreference();

    notifyListeners();
  }
}
