// lib/data/services/shared_preferences_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/settings/domain/models/api_key_model.dart';
import '../../features/settings/domain/models/prompt_model.dart';
import '../../features/ai_assistant/domain/models/chat_message_model.dart';
import '../../features/settings/application/services/settings_service.dart';
import 'lain/path_service.dart';
import 'gemini_service.dart';
import 'user_data_service.dart';

class SharedPreferencesService {
  final SettingsService _settingsService = SettingsService();
  final PathService _pathService = PathService();
  final GeminiService _geminiService = GeminiService();
  final UserDataService _userDataService = UserDataService();

  // Metode untuk Pengaturan
  Future<void> saveThemePreference(bool isDarkMode) =>
      _settingsService.saveThemePreference(isDarkMode);
  Future<bool> loadThemePreference() => _settingsService.loadThemePreference();
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

  // Metode untuk Gemini
  Future<void> saveApiKeys(List<ApiKey> keys) =>
      _geminiService.saveApiKeys(keys);
  Future<List<ApiKey>> loadApiKeys() => _geminiService.loadApiKeys();
  Future<void> saveGeminiContentModel(String modelId) =>
      _geminiService.saveGeminiContentModel(modelId);
  Future<String?> loadGeminiContentModel() =>
      _geminiService.loadGeminiContentModel();
  Future<void> saveGeminiChatModel(String modelId) =>
      _geminiService.saveGeminiChatModel(modelId);
  Future<String?> loadGeminiChatModel() => _geminiService.loadGeminiChatModel();
  Future<void> saveGeminiGeneralModel(String modelId) =>
      _geminiService.saveGeminiGeneralModel(modelId);
  Future<String?> loadGeminiGeneralModel() =>
      _geminiService.loadGeminiGeneralModel();
  Future<void> savePrompts(List<Prompt> prompts) =>
      _geminiService.savePrompts(prompts);
  Future<List<Prompt>> loadPrompts() => _geminiService.loadPrompts();
  Future<Prompt> getActivePrompt() => _geminiService.getActivePrompt();

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
