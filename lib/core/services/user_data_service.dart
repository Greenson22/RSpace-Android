// lib/core/services/user_data_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/ai_assistant/domain/models/chat_message_model.dart';
import 'path_service.dart';

class UserDataService {
  // Kunci enkripsi sederhana (JANGAN GUNAKAN INI DI PRODUKSI)
  static const String _encryptionKey = "RSpaceSecretKey";

  // Enkripsi XOR sederhana (HANYA UNTUK DEMONSTRASI)
  Uint8List _xorEncrypt(String text) {
    final keyBytes = utf8.encode(_encryptionKey);
    final textBytes = utf8.encode(text);
    final encryptedBytes = Uint8List(textBytes.length);
    for (int i = 0; i < textBytes.length; i++) {
      encryptedBytes[i] = textBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return encryptedBytes;
  }

  // Dekripsi XOR sederhana
  String _xorDecrypt(Uint8List encryptedBytes) {
    final keyBytes = utf8.encode(_encryptionKey);
    final decryptedBytes = Uint8List(encryptedBytes.length);
    for (int i = 0; i < encryptedBytes.length; i++) {
      decryptedBytes[i] = encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return utf8.decode(decryptedBytes);
  }

  // Membaca semua data profil dari file
  Future<Map<String, dynamic>> _loadProfileData() async {
    final pathService = PathService();
    final filePath = await pathService.userProfilePath;
    final file = File(filePath);

    if (await file.exists()) {
      try {
        final encryptedBytes = await file.readAsBytes();
        final jsonString = _xorDecrypt(encryptedBytes);
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        // Jika gagal dekripsi atau parsing, kembalikan data default
        return {};
      }
    }
    return {};
  }

  // Menyimpan semua data profil ke file
  Future<void> _saveProfileData(Map<String, dynamic> data) async {
    final pathService = PathService();
    final filePath = await pathService.userProfilePath;
    final file = File(filePath);
    final jsonString = jsonEncode(data);
    final encryptedBytes = _xorEncrypt(jsonString);
    await file.writeAsBytes(encryptedBytes);
  }

  Future<void> saveNeurons(int count) async {
    final data = await _loadProfileData();
    data['neurons'] = count;
    await _saveProfileData(data);
  }

  Future<int> loadNeurons() async {
    final data = await _loadProfileData();
    return data['neurons'] as int? ?? 0; // Default 0 jika tidak ada
  }

  static const String _geminiChatHistory = 'gemini_chat_history';
  static const String _sortTypeKey = 'sort_type';
  static const String _sortAscendingKey = 'sort_ascending';
  static const String _filterTypeKey = 'filter_type';
  static const String _filterValueKey = 'filter_value';
  static const String _backupSortTypeKey = 'backup_sort_type';
  static const String _backupSortAscendingKey = 'backup_sort_ascending';

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
    final sortType = prefs.getString(_sortTypeKey) ?? 'date';
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
}
