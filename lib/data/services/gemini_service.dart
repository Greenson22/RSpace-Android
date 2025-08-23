// lib/data/services/gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // Ganti dengan API Key Anda
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';
  static const String _model = 'gemini-pro';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey';

  Future<String> generateHtmlContent(String topic) async {
    if (_apiKey == 'AIzaSyDKjWo0bbXhcxxeltGv2KaC8dNLDz3i4jM') {
      throw Exception(
        'API Key Gemini belum diatur di lib/data/services/gemini_service.dart',
      );
    }

    // Prompt ini berfungsi baik untuk judul maupun deskripsi panjang.
    final prompt =
        'Buatkan saya konten HTML untuk pembahasan tentang "$topic". '
        'Tolong berikan hanya kode HTML untuk bagian body saja, tanpa tag <html>, <head>, atau <body>. '
        'Gunakan tag seperti <h2> untuk judul utama, <h3> untuk sub-judul, <p> untuk paragraf, '
        '<ul> dan <li> untuk daftar, dan <strong> atau <em> untuk penekanan. '
        'Pastikan strukturnya rapi dan informatif.';

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
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
        // Mengakses bagian teks dengan aman
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
