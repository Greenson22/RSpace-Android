// lib/core/services/neuron_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'path_service.dart';

/// A dedicated service to manage the user's neuron count with simple encryption.
class NeuronService {
  final PathService _pathService = PathService();

  // Simple encryption key (DO NOT USE THIS IN PRODUCTION)
  static const String _encryptionKey = "RSpaceSecretKeyForNeurons";

  // Simple XOR encryption
  Uint8List _xorEncrypt(String text) {
    final keyBytes = utf8.encode(_encryptionKey);
    final textBytes = utf8.encode(text);
    final encryptedBytes = Uint8List(textBytes.length);
    for (int i = 0; i < textBytes.length; i++) {
      encryptedBytes[i] = textBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return encryptedBytes;
  }

  // Simple XOR decryption
  String _xorDecrypt(Uint8List encryptedBytes) {
    final keyBytes = utf8.encode(_encryptionKey);
    final decryptedBytes = Uint8List(encryptedBytes.length);
    for (int i = 0; i < encryptedBytes.length; i++) {
      decryptedBytes[i] = encryptedBytes[i] ^ keyBytes[i % keyBytes.length];
    }
    return utf8.decode(decryptedBytes);
  }

  /// Loads the user's profile data from an encrypted file.
  Future<Map<String, dynamic>> _loadProfileData() async {
    final filePath = await _pathService.userProfilePath;
    final file = File(filePath);

    if (await file.exists()) {
      try {
        final encryptedBytes = await file.readAsBytes();
        if (encryptedBytes.isEmpty) return {};
        final jsonString = _xorDecrypt(encryptedBytes);
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        // If decryption or parsing fails, return default data.
        return {};
      }
    }
    return {};
  }

  /// Saves the user's profile data to an encrypted file.
  Future<void> _saveProfileData(Map<String, dynamic> data) async {
    final filePath = await _pathService.userProfilePath;
    final file = File(filePath);
    final jsonString = jsonEncode(data);
    final encryptedBytes = _xorEncrypt(jsonString);
    await file.writeAsBytes(encryptedBytes);
  }

  /// Loads the current neuron count.
  Future<int> getNeurons() async {
    final data = await _loadProfileData();
    return data['neurons'] as int? ?? 0;
  }

  /// Adds a specified amount to the current neuron count.
  Future<void> addNeurons(int amount) async {
    final currentNeurons = await getNeurons();
    final data = await _loadProfileData();
    data['neurons'] = currentNeurons + amount;
    await _saveProfileData(data);
  }

  /// Spends a specified amount of neurons if available.
  /// Returns true if the transaction was successful, false otherwise.
  Future<bool> spendNeurons(int amount) async {
    final currentNeurons = await getNeurons();
    if (currentNeurons >= amount) {
      final data = await _loadProfileData();
      data['neurons'] = currentNeurons - amount;
      await _saveProfileData(data);
      return true;
    }
    return false;
  }
}
