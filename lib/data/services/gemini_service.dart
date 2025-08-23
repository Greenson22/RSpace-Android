// lib/data/services/gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_key_model.dart';
import 'shared_preferences_service.dart';

class GeminiService {
  final SharedPreferencesService _prefsService = SharedPreferencesService();

  // Helper untuk mendapatkan API key yang aktif
  Future<String> _getActiveApiKey() async {
    final List<ApiKey> keys = await _prefsService.loadApiKeys();
    try {
      // Cari kunci pertama yang isActive == true
      final activeKey = keys.firstWhere((k) => k.isActive);
      return activeKey.key;
    } catch (e) {
      // Jika tidak ada yang aktif, kembalikan string kosong
      return '';
    }
  }

  Future<String> generateHtmlContent(String topic) async {
    final apiKey = await _getActiveApiKey();
    final model = await _prefsService.loadGeminiModel() ?? 'gemini-2.5-flash';

    if (apiKey.isEmpty) {
      throw Exception(
        'Tidak ada API Key Gemini yang aktif. Silakan atur melalui menu di Dashboard.',
      );
    }

    final apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

    final prompt =
        'Buatkan saya konten HTML untuk pembahasan tentang "$topic". '
        'Tolong berikan hanya kode HTML untuk bagian body saja, tanpa tag <html>, <head>, atau <body>. '
        'Gunakan tag seperti <h2> untuk judul utama, <h3> untuk sub-judul, <p> untuk paragraf, '
        '<ul> dan <li> untuk daftar, dan <strong> atau <em> untuk penekanan. '
        'Pastikan strukturnya rapi dan informatif.';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final candidates = body['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          if (content != null) {
            final parts = content['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
              return parts[0]['text'] as String? ?? '';
            }
          }
        }
        throw Exception('Gagal mem-parsing respons dari API Gemini.');
      } else {
        throw Exception(
          'Gagal menghasilkan konten: ${response.statusCode}\n${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
