// lib/data/services/gemini_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_key_model.dart';
// ==> IMPORT MODEL BARU
import '../../features/content_management/domain/models/discussion_model.dart';
import '../models/link_suggestion_model.dart';
import '../../core/services/storage_service.dart';

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

  // ==> FUNGSI BARU UNTUK SARAN IKON DENGAN GEMINI <==
  Future<List<String>> suggestIcon({required String name}) async {
    final apiKey = await _getActiveApiKey();
    final model =
        await _prefsService.loadGeminiGeneralModel() ?? 'gemini-1.5-flash';

    if (apiKey.isEmpty) {
      throw Exception('API Key Gemini tidak aktif.');
    }

    final prompt =
        '''
Berikan 5 rekomendasi emoji unicode yang paling relevan untuk item bernama "$name".
Aturan Jawaban:
1. HANYA kembalikan dalam format array JSON.
2. Setiap elemen dalam array HARUS berupa string emoji.
3. Jangan sertakan penjelasan atau teks lain di luar array JSON.

Contoh Jawaban:
["💡", "📚", "⚙️", "❤️", "⭐"]
''';

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
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {'responseMimeType': 'application/json'},
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final textResponse =
            body['candidates'][0]['content']['parts'][0]['text'];
        final List<dynamic> jsonResponse = jsonDecode(textResponse);
        return List<String>.from(jsonResponse);
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

  // ==> FUNGSI BARU UNTUK MENCARI TAUTAN CERDAS DENGAN GEMINI
  Future<List<LinkSuggestion>> findSmartLinks({
    required Discussion discussion,
    required List<Map<String, String>> allFiles,
  }) async {
    final apiKey = await _getActiveApiKey();
    final model =
        await _prefsService.loadGeminiGeneralModel() ?? 'gemini-1.5-flash';

    if (apiKey.isEmpty) {
      throw Exception('API Key Gemini tidak aktif.');
    }

    // Format daftar file menjadi string yang mudah dibaca oleh AI
    final fileListString = allFiles
        .map(
          (f) => "- Judul: \"${f['title']}\", Path: \"${f['relativePath']}\"",
        )
        .join("\n");

    // Format poin-poin diskusi
    final pointsString = discussion.points
        .map((p) => "- ${p.pointText}")
        .join("\n");

    final prompt =
        '''
      Anda adalah asisten AI yang bertugas menemukan file yang paling relevan.
      Berdasarkan detail diskusi berikut:
      - Judul Diskusi: "${discussion.discussion}"
      - Poin-Poin Catatan:
      $pointsString

      Pilihlah maksimal 3 file yang paling relevan dari daftar di bawah ini:
      $fileListString

      Aturan Jawaban:
      1.  HANYA kembalikan dalam format array JSON.
      2.  Setiap objek dalam array HARUS memiliki kunci "title" dan "relativePath".
      3.  Pastikan nilai "relativePath" persis sama dengan yang ada di daftar.
      4.  Jangan sertakan penjelasan atau teks lain di luar array JSON.

      Contoh Jawaban:
      [
        {"title": "Judul File Pilihan 1", "relativePath": "TopikA/SubjekB/file1.html"},
        {"title": "Judul File Pilihan 2", "relativePath": "TopikC/SubjekD/file2.html"}
      ]
      ''';

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
                {'text': prompt},
              ],
            },
          ],
          // Tambahkan pengaturan untuk memastikan output adalah JSON
          'generationConfig': {'responseMimeType': 'application/json'},
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final textResponse =
            body['candidates'][0]['content']['parts'][0]['text'];
        final List<dynamic> jsonResponse = jsonDecode(textResponse);

        return jsonResponse
            .map(
              (item) => LinkSuggestion(
                title: item['title'] ?? 'Tanpa Judul',
                relativePath: item['relativePath'] ?? '',
                score: 1.0, // Skor default untuk hasil AI
              ),
            )
            .toList();
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

  // ... (sisa kode getChatCompletion dan generateHtmlContent tidak berubah)
  Future<String> getChatCompletion(String query, {String? context}) async {
    final apiKey = await _getActiveApiKey();
    final model =
        await _prefsService.loadGeminiChatModel() ?? 'gemini-1.5-flash';

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
        await _prefsService.loadGeminiContentModel() ?? 'gemini-1.5-flash';

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
