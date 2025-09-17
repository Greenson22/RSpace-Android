// lib/core/services/storage_service.dart
import 'package:my_aplication/features/settings/application/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/ai_assistant/domain/models/chat_message_model.dart';
import 'path_service.dart';
import 'user_data_service.dart';
import 'neuron_service.dart';

class SharedPreferencesService {
  final SettingsService _settingsService = SettingsService();
  final PathService _pathService = PathService();
  final UserDataService _userDataService = UserDataService();
  final NeuronService _neuronService = NeuronService();

  // Update neuron methods to use NeuronService
  Future<void> saveNeurons(int count) => _neuronService.setNeurons(count);
  Future<int> loadNeurons() => _neuronService.getNeurons();

  // Metode untuk Pengaturan
  Future<void> saveThemePreference(bool isDarkMode) =>
      _settingsService.saveThemePreference(isDarkMode);
  Future<bool> loadThemePreference() => _settingsService.loadThemePreference();
  Future<void> saveChristmasThemePreference(bool isChristmas) =>
      _settingsService.saveChristmasThemePreference(isChristmas);
  Future<bool> loadChristmasThemePreference() =>
      _settingsService.loadChristmasThemePreference();
  Future<void> savePrimaryColor(int colorValue) =>
      _settingsService.savePrimaryColor(colorValue);
  Future<int?> loadPrimaryColor() => _settingsService.loadPrimaryColor();
  Future<void> saveRecentColors(List<int> colorValues) =>
      _settingsService.saveRecentColors(colorValues);
  Future<List<int>> loadRecentColors() => _settingsService.loadRecentColors();
  Future<void> saveBackgroundImagePath(String path) =>
      _settingsService.saveBackgroundImagePath(path);
  Future<String?> loadBackgroundImagePath() =>
      _settingsService.loadBackgroundImagePath();
  Future<void> clearBackgroundImagePath() =>
      _settingsService.clearBackgroundImagePath();
  Future<void> saveDashboardItemScale(double scale) =>
      _settingsService.saveDashboardItemScale(scale);
  Future<double> loadDashboardItemScale() =>
      _settingsService.loadDashboardItemScale();
  Future<void> saveShowFloPreference(bool showFlo) =>
      _settingsService.saveShowFloPreference(showFlo);
  Future<bool> loadShowFloPreference() =>
      _settingsService.loadShowFloPreference();
  Future<void> saveShowQuickFabPreference(bool show) =>
      _settingsService.saveShowQuickFabPreference(show);
  Future<bool> loadShowQuickFabPreference() =>
      _settingsService.loadShowQuickFabPreference();
  Future<void> saveShowQuickFabIconPreference(String icon) =>
      _settingsService.saveShowQuickFabIconPreference(icon);
  Future<String> loadShowQuickFabIconPreference() =>
      _settingsService.loadShowQuickFabIconPreference();
  Future<void> saveQuickFabBgOpacity(double opacity) =>
      _settingsService.saveQuickFabBgOpacity(opacity);
  Future<double> loadQuickFabBgOpacity() =>
      _settingsService.loadQuickFabBgOpacity();
  Future<void> saveQuickFabOverallOpacity(double opacity) =>
      _settingsService.saveQuickFabOverallOpacity(opacity);
  Future<double> loadQuickFabOverallOpacity() =>
      _settingsService.loadQuickFabOverallOpacity();
  Future<void> saveQuickFabSize(double size) =>
      _settingsService.saveQuickFabSize(size);
  Future<double> loadQuickFabSize() => _settingsService.loadQuickFabSize();
  Future<void> saveFabMenuShowTextPreference(bool showText) =>
      _settingsService.saveFabMenuShowTextPreference(showText);
  Future<bool> loadFabMenuShowTextPreference() =>
      _settingsService.loadFabMenuShowTextPreference();
  Future<void> saveOpenInAppBrowser(bool openInApp) =>
      _settingsService.saveOpenInAppBrowser(openInApp);
  Future<bool> loadOpenInAppBrowser() =>
      _settingsService.loadOpenInAppBrowser();

  Future<void> saveHtmlEditorTheme(String themeName) =>
      _settingsService.saveHtmlEditorTheme(themeName);
  Future<String?> loadHtmlEditorTheme() =>
      _settingsService.loadHtmlEditorTheme();

  Future<void> saveMyTasksLayoutPreference(bool isGridView) =>
      _settingsService.saveMyTasksLayoutPreference(isGridView);
  Future<bool> loadMyTasksLayoutPreference() =>
      _settingsService.loadMyTasksLayoutPreference();

  // Metode untuk Path
  Future<void> saveCustomStoragePath(String path) =>
      _pathService.saveCustomStoragePath(path);
  Future<String?> loadCustomStoragePath() =>
      _pathService.loadCustomStoragePath();
  Future<void> saveCustomBackupPath(String path) =>
      _pathService.saveCustomBackupPath(path);
  Future<String?> loadCustomBackupPath() => _pathService.loadCustomBackupPath();
  Future<void> saveCustomDownloadPath(String path) =>
      _pathService.saveCustomDownloadPath(path);
  Future<String?> loadCustomDownloadPath() =>
      _pathService.loadCustomDownloadPath();
  Future<void> savePerpuskuDataPath(String path) =>
      _pathService.savePerpuskuDataPath(path);
  Future<String?> loadPerpuskuDataPath() => _pathService.loadPerpuskuDataPath();

  // Metode untuk Data Pengguna
  Future<void> saveChatHistory(List<ChatMessage> messages) =>
      _userDataService.saveChatHistory(messages);
  Future<List<ChatMessage>> loadChatHistory() =>
      _userDataService.loadChatHistory();
  Future<void> saveSortPreferences(String sortType, bool sortAscending) =>
      _userDataService.saveSortPreferences(sortType, sortAscending);
  Future<Map<String, dynamic>> loadSortPreferences() =>
      _userDataService.loadSortPreferences();
  Future<void> saveFilterPreference(String? filterType, String? filterValue) =>
      _userDataService.saveFilterPreference(filterType, filterValue);
  Future<Map<String, String?>> loadFilterPreference() =>
      _userDataService.loadFilterPreference();
  Future<void> saveBackupSortPreferences(String sortType, bool sortAscending) =>
      _userDataService.saveBackupSortPreferences(sortType, sortAscending);
  Future<Map<String, dynamic>> loadBackupSortPreferences() =>
      _userDataService.loadBackupSortPreferences();
  Future<void> saveExcludedSubjects(List<String> subjectIds) =>
      _userDataService.saveExcludedSubjects(subjectIds);
  Future<Set<String>> loadExcludedSubjects() =>
      _userDataService.loadExcludedSubjects();

  Future<void> saveExcludedTaskCategories(List<String> categoryNames) =>
      _userDataService.saveExcludedTaskCategories(categoryNames);
  Future<Set<String>> loadExcludedTaskCategories() =>
      _userDataService.loadExcludedTaskCategories();

  Future<void> saveRepetitionCodeOrder(List<String> order) =>
      _userDataService.saveRepetitionCodeOrder(order);
  Future<List<String>> loadRepetitionCodeOrder() =>
      _userDataService.loadRepetitionCodeOrder();

  Future<void> saveRepetitionCodeDisplayOrder(List<String> order) =>
      _userDataService.saveRepetitionCodeDisplayOrder(order);
  Future<List<String>> loadRepetitionCodeDisplayOrder() =>
      _userDataService.loadRepetitionCodeDisplayOrder();

  Future<void> saveRepetitionCodeDays(Map<String, int> days) =>
      _userDataService.saveRepetitionCodeDays(days);
  Future<Map<String, int>> loadRepetitionCodeDays() =>
      _userDataService.loadRepetitionCodeDays();

  // Konfigurasi API lama
  static const String _apiDomainKey = 'api_domain';
  static const String _apiKeyKey = 'api_key';

  Future<void> saveApiConfig(String domain, String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiDomainKey, domain);
    await prefs.setString(_apiKeyKey, apiKey);
  }

  Future<Map<String, String?>> loadApiConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final domain = prefs.getString(_apiDomainKey);
    final apiKey = prefs.getString(_apiKeyKey);
    return {'domain': domain, 'apiKey': apiKey};
  }
}
