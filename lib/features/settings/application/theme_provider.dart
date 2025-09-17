// lib/features/settings/application/theme_provider.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:my_aplication/features/settings/application/theme_settings_service.dart';
import 'package:my_aplication/features/settings/domain/models/theme_settings_model.dart';
import '../../../core/theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  final ThemeSettingsService _settingsService = ThemeSettingsService();
  late ThemeSettings _settings;

  // Getters that expose settings to the UI
  bool get darkTheme => _settings.isDarkMode;
  Color get primaryColor => Color(_settings.primaryColorValue);
  List<Color> get recentColors =>
      _settings.recentColorValues.map((v) => Color(v)).toList();
  bool get isChristmasTheme => _settings.isChristmasTheme;
  String? get backgroundImagePath => _settings.backgroundImagePath;
  double get dashboardItemScale => _settings.dashboardItemScale;
  bool get showFloatingCharacter => _settings.showFloatingCharacter;
  bool get showQuickFab => _settings.showQuickFab;
  String get quickFabIcon => _settings.quickFabIcon;
  double get quickFabBgOpacity => _settings.quickFabBgOpacity;
  double get quickFabOverallOpacity => _settings.quickFabOverallOpacity;
  double get quickFabSize => _settings.quickFabSize;
  bool get fabMenuShowText => _settings.fabMenuShowText;
  bool get openInAppBrowser => _settings.openInAppBrowser;
  String? get htmlEditorTheme => _settings.htmlEditorTheme;

  ThemeData get currentTheme {
    if (_settings.isChristmasTheme) {
      return AppTheme.getChristmasTheme(_settings.isDarkMode);
    }
    return AppTheme.getTheme(
      Color(_settings.primaryColorValue),
      _settings.isDarkMode,
    );
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _settings = await _settingsService.loadSettings();
    notifyListeners();
  }

  Future<void> _saveAndUpdate(ThemeSettings newSettings) async {
    _settings = newSettings;
    await _settingsService.saveSettings(_settings);
    notifyListeners();
  }

  void updateTheme({
    bool? isDark,
    bool? isChristmas,
    Color? color,
    double? dashboardScale,
  }) {
    _settings = _settings.copyWith(
      isDarkMode: isDark,
      isChristmas: isChristmas,
      primaryColorValue: color?.value,
      dashboardItemScale: dashboardScale,
    );

    if (color != null) {
      _addRecentColor(color);
    }
    _saveAndUpdate(_settings);
  }

  void toggleFloatingCharacter() {
    _saveAndUpdate(
      _settings.copyWith(
        showFloatingCharacter: !_settings.showFloatingCharacter,
      ),
    );
  }

  void toggleOpenInAppBrowser() {
    _saveAndUpdate(
      _settings.copyWith(openInAppBrowser: !_settings.openInAppBrowser),
    );
  }

  Future<void> updateQuickFabSettings({
    bool? show,
    String? icon,
    double? bgOpacity,
    double? overallOpacity,
    double? size,
    bool? showMenuText,
  }) async {
    _saveAndUpdate(
      _settings.copyWith(
        showQuickFab: show,
        quickFabIcon: icon,
        quickFabBgOpacity: bgOpacity,
        quickFabOverallOpacity: overallOpacity,
        quickFabSize: size,
        fabMenuShowText: showMenuText,
      ),
    );
  }

  Future<void> setBackgroundImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      _saveAndUpdate(
        _settings.copyWith(backgroundImagePath: () => result.files.single.path),
      );
    }
  }

  Future<void> clearBackgroundImagePath() async {
    _saveAndUpdate(_settings.copyWith(backgroundImagePath: () => null));
  }

  void _addRecentColor(Color color) {
    final recent = recentColors;
    recent.remove(color);
    recent.insert(0, color);
    if (recent.length > 6) {
      final sublist = recent.sublist(0, 6);
      _settings = _settings.copyWith(
        recentColorValues: sublist.map((c) => c.value).toList(),
      );
    } else {
      _settings = _settings.copyWith(
        recentColorValues: recent.map((c) => c.value).toList(),
      );
    }
  }

  Future<void> saveHtmlEditorTheme(String themeName) async {
    _saveAndUpdate(_settings.copyWith(htmlEditorTheme: () => themeName));
  }
}
