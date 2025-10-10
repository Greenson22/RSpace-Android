// lib/core/services/user_data_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/ai_assistant/domain/models/chat_message_model.dart';

class UserDataService {
  static const String _geminiChatHistory = 'gemini_chat_history';
  static const String _sortTypeKey = 'sort_type';
  static const String _sortAscendingKey = 'sort_ascending';
  static const String _filterTypeKey = 'filter_type';
  static const String _filterValueKey = 'filter_value';
  static const String _backupSortTypeKey = 'backup_sort_type';
  static const String _backupSortAscendingKey = 'backup_sort_ascending';
  static const String _repetitionCodeOrderKey = 'repetition_code_order';
  static const String _repetitionCodeDisplayOrderKey =
      'repetition_code_display_order';
  static const String _repetitionCodeDaysKey = 'repetition_code_days';
  static const String _timelineDiscussionRadiusKey =
      'timeline_discussion_radius';
  static const String _timelinePointRadiusKey = 'timeline_point_radius';
  static const String _timelineDiscussionSpacingKey =
      'timeline_discussion_spacing';
  static const String _timelinePointSpacingKey = 'timeline_point_spacing';
  // ==> KUNCI BARU UNTUK ZOOM <==
  static const String _timelineZoomLevelKey = 'timeline_zoom_level';

  Future<void> saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> loadString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  // ==> FUNGSI INI DIPERBARUI <==
  Future<void> saveTimelineAppearance({
    double? discussionRadius,
    double? pointRadius,
    double? discussionSpacing,
    double? pointSpacing,
    double? zoomLevel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (discussionRadius != null) {
      await prefs.setDouble(_timelineDiscussionRadiusKey, discussionRadius);
    }
    if (pointRadius != null) {
      await prefs.setDouble(_timelinePointRadiusKey, pointRadius);
    }
    if (discussionSpacing != null) {
      await prefs.setDouble(_timelineDiscussionSpacingKey, discussionSpacing);
    }
    if (pointSpacing != null) {
      await prefs.setDouble(_timelinePointSpacingKey, pointSpacing);
    }
    if (zoomLevel != null) {
      await prefs.setDouble(_timelineZoomLevelKey, zoomLevel);
    }
  }

  // ==> FUNGSI INI DIPERBARUI <==
  Future<Map<String, double>> loadTimelineAppearance() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'discussionRadius': prefs.getDouble(_timelineDiscussionRadiusKey) ?? 6.0,
      'pointRadius': prefs.getDouble(_timelinePointRadiusKey) ?? 4.0,
      'discussionSpacing':
          prefs.getDouble(_timelineDiscussionSpacingKey) ?? 10.0,
      'pointSpacing': prefs.getDouble(_timelinePointSpacingKey) ?? 8.0,
      'zoomLevel': prefs.getDouble(_timelineZoomLevelKey) ?? 1.0,
    };
  }

  Future<void> saveChatHistory(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = encodeChatMessages(messages);
    await prefs.setString(_geminiChatHistory, encodedData);
  }

  Future<List<ChatMessage>> loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_geminiChatHistory);
    return decodeChatMessages(encodedData ?? '[]');
  }

  Future<void> saveSortPreferences(String sortType, bool sortAscending) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortTypeKey, sortType);
    await prefs.setBool(_sortAscendingKey, sortAscending);
  }

  Future<Map<String, dynamic>> loadSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final sortType = prefs.getString(_sortTypeKey) ?? 'position';
    final sortAscending = prefs.getBool(_sortAscendingKey) ?? true;
    return {'sortType': sortType, 'sortAscending': sortAscending};
  }

  Future<void> saveFilterPreference(
    String? filterType,
    String? filterValue,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (filterType != null) {
      await prefs.setString(_filterTypeKey, filterType);
    } else {
      await prefs.remove(_filterTypeKey);
    }
    if (filterValue != null) {
      await prefs.setString(_filterValueKey, filterValue);
    } else {
      await prefs.remove(_filterValueKey);
    }
  }

  Future<Map<String, String?>> loadFilterPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final filterType = prefs.getString(_filterTypeKey);
    final filterValue = prefs.getString(_filterValueKey);
    return {'filterType': filterType, 'filterValue': filterValue};
  }

  Future<void> saveBackupSortPreferences(
    String sortType,
    bool sortAscending,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backupSortTypeKey, sortType);
    await prefs.setBool(_backupSortAscendingKey, sortAscending);
  }

  Future<Map<String, dynamic>> loadBackupSortPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final sortType = prefs.getString(_backupSortTypeKey) ?? 'date';
    final sortAscending = prefs.getBool(_backupSortAscendingKey) ?? false;
    return {'sortType': sortType, 'sortAscending': sortAscending};
  }

  Future<void> saveRepetitionCodeOrder(List<String> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_repetitionCodeOrderKey, order);
  }

  Future<List<String>> loadRepetitionCodeOrder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_repetitionCodeOrderKey) ?? [];
  }

  Future<void> saveRepetitionCodeDisplayOrder(List<String> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_repetitionCodeDisplayOrderKey, order);
  }

  Future<List<String>> loadRepetitionCodeDisplayOrder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_repetitionCodeDisplayOrderKey) ?? [];
  }

  Future<void> saveRepetitionCodeDays(Map<String, int> days) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(
      days.map((key, value) => MapEntry(key, value.toString())),
    );
    await prefs.setString(_repetitionCodeDaysKey, jsonString);
  }

  Future<Map<String, int>> loadRepetitionCodeDays() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_repetitionCodeDaysKey);
    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }
    final Map<String, dynamic> decodedMap = jsonDecode(jsonString);
    return decodedMap.map(
      (key, value) => MapEntry(key, int.tryParse(value) ?? 0),
    );
  }
}
