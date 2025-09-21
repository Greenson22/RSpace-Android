// lib/core/services/storage_service.dart
import 'package:my_aplication/features/settings/application/services/settings_service.dart';
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
  Future<void> saveMyTasksLayoutPreference(bool isGridView) =>
      _settingsService.saveMyTasksLayoutPreference(isGridView);
  Future<bool> loadMyTasksLayoutPreference() =>
      _settingsService.loadMyTasksLayoutPreference();

  // Metode untuk Path
  Future<void> saveCustomStoragePath(String path) =>
      _pathService.saveCustomStoragePath(path);
  Future<String?> loadCustomStoragePath() =>
      _pathService.loadCustomStoragePath();

  // Fungsi untuk save/load customDownloadPath telah dihapus

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
}
