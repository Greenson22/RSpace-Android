// lib/features/archive/application/archive_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:my_aplication/features/settings/application/services/api_config_service.dart';

class ArchiveService {
  final ApiConfigService _apiConfigService = ApiConfigService();

  /// Mengunggah file arsip diskusi ke server.
  ///
  /// Melemparkan exception jika terjadi kegagalan.
  Future<String> uploadArchive(File archiveFile) async {
    final apiConfig = await _apiConfigService.loadConfig();
    final apiDomain = apiConfig['domain'];
    final apiKey = apiConfig['apiKey'];

    if (apiDomain == null ||
        apiKey == null ||
        apiDomain.isEmpty ||
        apiKey.isEmpty) {
      throw Exception('Konfigurasi API (domain/key) tidak ditemukan.');
    }

    // Endpoint baru yang sudah Anda buat di backend
    final url = '$apiDomain/api/archive/discussions';
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers['x-api-key'] = apiKey;

    // 'zipfile' harus cocok dengan key yang digunakan di middleware Multer
    request.files.add(
      await http.MultipartFile.fromPath('zipfile', archiveFile.path),
    );

    final response = await request.send();

    if (response.statusCode != 201 && response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      String errorMessage = 'Error tidak diketahui';
      try {
        final decodedBody = json.decode(responseBody);
        errorMessage = decodedBody is Map && decodedBody.containsKey('message')
            ? decodedBody['message']
            : responseBody;
      } catch (_) {
        errorMessage = responseBody;
      }
      throw HttpException(
        'Gagal mengunggah arsip: $errorMessage (Status ${response.statusCode})',
      );
    }

    final responseBody = await response.stream.bytesToString();
    final decodedBody = json.decode(responseBody);
    return decodedBody['message'] ?? 'Arsip berhasil diunggah.';
  }
}
