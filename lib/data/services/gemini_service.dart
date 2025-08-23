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

    // ==> PROMPT BARU SESUAI PERMINTAAN ANDA <==
    final prompt =
        '''
Buatkan saya konten HTML untuk dimasukkan ke dalam body sebuah website, berdasarkan pembahasan tentang: "$topic".

Ikuti aturan-aturan berikut dengan ketat:
1. Gunakan HANYA inline CSS untuk semua styling. Jangan gunakan tag <style>.
2. Bungkus seluruh konten dalam satu div utama. Berikan div utama ini style background warna biru muda (misalnya, `style="background-color: #f0f8ff; padding: 20px; border-radius: 8px;"`).
3. Letakkan judul utama di dalam sebuah div tersendiri dengan styling yang menarik (misalnya, `style="background-color: #4a90e2; color: white; padding: 15px; text-align: center; font-size: 24px; border-radius: 5px;"`).
4. Gunakan warna-warni yang harmonis untuk teks paragraf dan sub-judul. Contohnya, gunakan warna seperti `#333` untuk teks biasa, dan warna biru atau hijau tua untuk sub-judul.
5. Jika ada blok kode, gunakan tag `<pre>` dan `<code>`. Beri style pada tag `<pre>` agar terlihat seperti blok kode (misalnya, `style="background-color: #2d2d2d; color: #f8f8f2; padding: 15px; border-radius: 5px; overflow-x: auto; font-family: monospace;"`). Di dalam tag `<code>`, gunakan tag `<span>` dengan warna berbeda untuk menyorot keyword, string, dan komentar jika memungkinkan, sesuai bahasa pemrogramannya.
6. Sertakan simbol-simbol atau emoji yang relevan (contoh: 💡, 🚀, ✅) untuk memperkaya konten secara visual di tempat yang sesuai.
7. Pastikan outputnya adalah HANYA kode HTML, tanpa penjelasan tambahan di luar kode.
''';

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
        // Coba parsing error message dari respons API
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error']?['message'] ?? response.body;
        throw Exception(
          'Gagal menghasilkan konten: ${response.statusCode}\nError: $errorMessage',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
