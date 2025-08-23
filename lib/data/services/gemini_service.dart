// lib/data/services/gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_key_model.dart';
import 'shared_preferences_service.dart';

class GeminiService {
  final SharedPreferencesService _prefsService = SharedPreferencesService();

  Future<String> _getActiveApiKey() async {
    final List<ApiKey> keys = await _prefsService.loadApiKeys();
    try {
      final activeKey = keys.firstWhere((k) => k.isActive);
      return activeKey.key;
    } catch (e) {
      return '';
    }
  }

  Future<String> getChatCompletion(String query, {String? context}) async {
    final apiKey = await _getActiveApiKey();
    final model =
        await _prefsService.loadGeminiChatModel() ?? 'gemini-2.5-flash';

    if (apiKey.isEmpty) {
      throw Exception(
        'Tidak ada API Key Gemini yang aktif. Silakan atur melalui menu di Dashboard.',
      );
    }

    final apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

    final prompt =
        '''
Anda adalah "Flo", asisten AI yang terintegrasi di dalam aplikasi bernama RSpace.
Tugas Anda adalah menjawab pertanyaan pengguna berdasarkan data yang mereka miliki di dalam aplikasi.
Selalu jawab dalam Bahasa Indonesia dengan gaya yang ramah dan membantu.

Berikut adalah ringkasan data pengguna saat ini:
$context

Pertanyaan Pengguna: "$query"

Jawaban Anda:
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
              return parts[0]['text'] as String? ??
                  'Maaf, saya tidak bisa memproses permintaan itu.';
            }
          }
        }
        throw Exception('Gagal mem-parsing respons dari API Gemini.');
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error']?['message'] ?? response.body;
        throw Exception(
          'Gagal mendapatkan respons: ${response.statusCode}\nError: $errorMessage',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> generateHtmlContent(String topic) async {
    final apiKey = await _getActiveApiKey();
    final model =
        await _prefsService.loadGeminiContentModel() ?? 'gemini-2.5-flash';

    if (apiKey.isEmpty) {
      throw Exception(
        'Tidak ada API Key Gemini yang aktif. Silakan atur melalui menu di Dashboard.',
      );
    }

    final activePrompt = await _prefsService.getActivePrompt();
    final promptText = activePrompt.content.replaceAll('{topic}', topic);

    final apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': promptText},
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
