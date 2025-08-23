// lib/data/services/gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'shared_preferences_service.dart';

class GeminiService {
  // Hapus model statis dari sini
  final SharedPreferencesService _prefsService = SharedPreferencesService();

  Future<String> generateHtmlContent(String topic) async {
    final apiKey = await _prefsService.loadGeminiApiKey();
    // Muat model yang dipilih, atau gunakan default jika belum ada
    final model = await _prefsService.loadGeminiModel() ?? 'gemini-2.5-flash';

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'API Key Gemini belum diatur. Silakan atur melalui menu di Dashboard.',
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
