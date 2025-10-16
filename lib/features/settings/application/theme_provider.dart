// lib/features/settings/application/theme_provider.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/core/services/storage_service.dart';
import 'package:my_aplication/features/settings/application/theme_settings_service.dart';
import 'package:my_aplication/features/settings/domain/models/theme_settings_model.dart';
import '../../../core/theme/app_theme.dart';
import 'package:path/path.dart' as path;

class ThemeProvider with ChangeNotifier {
  final ThemeSettingsService _settingsService = ThemeSettingsService();
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final PathService _pathService = PathService();
  ThemeSettings? _settings;
  String? _localBackgroundImagePath;
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  bool get darkTheme => _settings?.isDarkMode ?? false;
  Color get primaryColor => _settings != null
      ? Color(_settings!.primaryColorValue)
      : AppTheme.selectableColors.first;
  List<Color> get recentColors =>
      _settings?.recentColorValues.map((v) => Color(v)).toList() ?? [];
  bool get isChristmasTheme => _settings?.isChristmasTheme ?? false;
  bool get isUnderwaterTheme => _settings?.isUnderwaterTheme ?? false;
  String? get backgroundImagePath => _localBackgroundImagePath;
  double get dashboardItemScale => _settings?.dashboardItemScale ?? 1.0;
  double get uiScaleFactor => _settings?.uiScaleFactor ?? 1.0;
  double get dashboardComponentOpacity =>
      _settings?.dashboardComponentOpacity ?? 0.9;
  bool get showFloatingCharacter => _settings?.showFloatingCharacter ?? true;
  bool get showQuickFab => _settings?.showQuickFab ?? true;
  String get quickFabIcon => _settings?.quickFabIcon ?? '➕';
  double get quickFabBgOpacity => _settings?.quickFabBgOpacity ?? 1.0;
  double get quickFabOverallOpacity => _settings?.quickFabOverallOpacity ?? 1.0;
  double get quickFabSize => _settings?.quickFabSize ?? 56.0;
  bool get fabMenuShowText => _settings?.fabMenuShowText ?? true;
  bool get openInAppBrowser => _settings?.openInAppBrowser ?? true;
  String? get htmlEditorTheme => _settings?.htmlEditorTheme;
  String get defaultNoteIcon => _settings?.defaultNoteIcon ?? '🗒️';
  String? get defaultHtmlEditor => _settings?.defaultHtmlEditor;

  ThemeData get currentTheme {
    if (_settings == null) {
      return AppTheme.getTheme(AppTheme.selectableColors.first, false);
    }
    if (_settings!.isChristmasTheme) {
      return AppTheme.getChristmasTheme(_settings!.isDarkMode);
    }
    if (_settings!.isUnderwaterTheme) {
      return AppTheme.getUnderwaterTheme(_settings!.isDarkMode);
    }
    return AppTheme.getTheme(
      Color(_settings!.primaryColorValue),
      _settings!.isDarkMode,
    );
  }

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _settings = await _settingsService.loadSettings();
    _localBackgroundImagePath = await _prefsService
        .loadLocalBackgroundImagePath();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveAndUpdate(ThemeSettings newSettings) async {
    _settings = newSettings;
    await _settingsService.saveSettings(_settings!);
    notifyListeners();
  }

  Future<void> updateDefaultNoteIcon(String newIcon) async {
    if (_settings == null) return;
    _saveAndUpdate(_settings!.copyWith(defaultNoteIcon: newIcon));
  }

  void updateTheme({
    bool? isDark,
    bool? isChristmas,
    bool? isUnderwater,
    Color? color,
    double? dashboardScale,
    double? uiScale,
    double? dashboardComponentOpacity,
  }) {
    if (_settings == null) return;
    _settings = _settings!.copyWith(
      isDarkMode: isDark,
      isChristmasTheme: isChristmas,
      isUnderwaterTheme: isUnderwater,
      primaryColorValue: color?.value,
      dashboardItemScale: dashboardScale,
      uiScaleFactor: uiScale,
      dashboardComponentOpacity: dashboardComponentOpacity,
    );

    if (color != null) {
      _addRecentColor(color);
    }
    _saveAndUpdate(_settings!);
  }

  void toggleFloatingCharacter() {
    if (_settings == null) return;
    _saveAndUpdate(
      _settings!.copyWith(
        showFloatingCharacter: !_settings!.showFloatingCharacter,
      ),
    );
  }

  void toggleOpenInAppBrowser() {
    if (_settings == null) return;
    _saveAndUpdate(
      _settings!.copyWith(openInAppBrowser: !_settings!.openInAppBrowser),
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
    if (_settings == null) return;
    _saveAndUpdate(
      _settings!.copyWith(
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
      final sourceFile = File(result.files.single.path!);
      final assetsPath = await _pathService.assetsPath;
      final fileExtension = path.extension(sourceFile.path);
      final uniqueFileName =
          'local_background_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final destinationPath = path.join(assetsPath, uniqueFileName);
      final destinationFile = File(destinationPath);

      await clearBackgroundImagePath();

      await sourceFile.copy(destinationFile.path);

      await _prefsService.saveLocalBackgroundImagePath(destinationFile.path);
      _localBackgroundImagePath = destinationFile.path;
      notifyListeners();
    }
  }

  Future<void> clearBackgroundImagePath() async {
    if (_localBackgroundImagePath != null) {
      final file = File(_localBackgroundImagePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await _prefsService.clearLocalBackgroundImagePath();
    _localBackgroundImagePath = null;
    notifyListeners();
  }

  void _addRecentColor(Color color) {
    if (_settings == null) return;
    final recent = recentColors;
    recent.remove(color);
    recent.insert(0, color);
    if (recent.length > 6) {
      final sublist = recent.sublist(0, 6);
      _settings = _settings!.copyWith(
        recentColorValues: sublist.map((c) => c.value).toList(),
      );
    } else {
      _settings = _settings!.copyWith(
        recentColorValues: recent.map((c) => c.value).toList(),
      );
    }
  }

  Future<void> saveHtmlEditorTheme(String themeName) async {
    if (_settings == null) return;
    _saveAndUpdate(_settings!.copyWith(htmlEditorTheme: () => themeName));
  }

  // == PERBAIKAN UTAMA DI SINI ==
  Future<void> updateDefaultHtmlEditor(String? editorChoice) async {
    if (_settings == null) return;
    // Gunakan ValueGetter untuk menangani kasus null dengan benar
    _saveAndUpdate(_settings!.copyWith(defaultHtmlEditor: () => editorChoice));
  }
}
