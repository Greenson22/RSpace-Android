// lib/features/content_management/domain/services/encryption_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  enc.Key _generateKey(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return enc.Key.fromBase64(base64Url.encode(digest.bytes));
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String encryptContent(String jsonContent, String password) {
    final key = _generateKey(password);
    final iv = enc.IV.fromLength(16);
    final encrypter = enc.Encrypter(enc.AES(key));
    final encrypted = encrypter.encrypt(jsonContent, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  String decryptContent(String encryptedContent, String password) {
    try {
      final parts = encryptedContent.split(':');
      if (parts.length != 2)
        throw Exception('Format konten terenkripsi tidak valid.');
      final iv = enc.IV.fromBase64(parts[0]);
      final encryptedData = enc.Encrypted.fromBase64(parts[1]);
      final key = _generateKey(password);
      final encrypter = enc.Encrypter(enc.AES(key));
      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      throw Exception('Gagal mendekripsi konten. Password mungkin salah.');
    }
  }

  // ==> FUNGSI BARU UNTUK ENKRIPSI FILE <==
  Future<void> encryptFile(File file, String password) async {
    if (!await file.exists()) return;
    final content = await file.readAsString();
    final encryptedContent = encryptContent(content, password);
    await file.writeAsString(encryptedContent);
  }

  // ==> FUNGSI BARU UNTUK DEKRIPSI FILE <==
  Future<void> decryptFile(File file, String password) async {
    if (!await file.exists()) return;
    final encryptedContent = await file.readAsString();
    try {
      final decryptedContent = decryptContent(encryptedContent, password);
      await file.writeAsString(decryptedContent);
    } catch (e) {
      // Jika dekripsi gagal, biarkan file tetap terenkripsi
      // Ini mencegah file rusak jika password salah.
    }
  }
}
