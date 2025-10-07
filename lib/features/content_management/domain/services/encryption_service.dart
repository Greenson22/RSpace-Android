// lib/features/content_management/domain/services/encryption_service.dart

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class EncryptionService {
  // Membuat kunci enkripsi dari password menggunakan SHA-256
  enc.Key _generateKey(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return enc.Key.fromBase64(base64Url.encode(digest.bytes));
  }

  // Menghasilkan hash dari password untuk verifikasi
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Mengenkripsi konten (string JSON)
  String encryptContent(String jsonContent, String password) {
    final key = _generateKey(password);
    final iv = enc.IV.fromLength(16); // Initialization Vector
    final encrypter = enc.Encrypter(enc.AES(key));

    final encrypted = encrypter.encrypt(jsonContent, iv: iv);
    // Gabungkan IV dan data terenkripsi agar bisa didekripsi nanti
    return '${iv.base64}:${encrypted.base64}';
  }

  // Mendekripsi konten
  String decryptContent(String encryptedContent, String password) {
    try {
      final parts = encryptedContent.split(':');
      if (parts.length != 2)
        throw Exception('Format konten terenkripsi tidak valid.');

      final iv = enc.IV.fromBase64(parts[0]);
      final encryptedData = enc.Encrypted.fromBase64(parts[1]);

      final key = _generateKey(password);
      final encrypter = enc.Encrypter(enc.AES(key));

      final decrypted = encrypter.decrypt(encryptedData, iv: iv);
      return decrypted;
    } catch (e) {
      // Jika dekripsi gagal (misalnya password salah), lempar error
      throw Exception('Gagal mendekripsi konten. Password mungkin salah.');
    }
  }
}
