// lib/features/settings/application/services/gemini_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/features/content_management/domain/services/discussion_service.dart';
import 'package:my_aplication/features/progress/domain/models/color_palette_model.dart';
import 'package:my_aplication/features/settings/application/gemini_settings_service.dart';
import '../../domain/models/api_key_model.dart';
import '../../../content_management/domain/models/discussion_model.dart';
import '../../../link_maintenance/domain/models/link_suggestion_model.dart';

class GeminiService {
  final GeminiSettingsService _settingsService = GeminiSettingsService();
  final DiscussionService _discussionService = DiscussionService();
  final PathService _pathService = PathService();

  final String _googleApiAuthority = 'generativelanguage.googleapis.com';

  Future<String> _getActiveApiKey() async {
    final settings = await _settingsService.loadSettings();
    try {
      final activeKey = settings.apiKeys.firstWhere((k) => k.isActive);
      return activeKey.key;
    } catch (e) {
      return '';
    }
  }

  Uri _buildApiUri(String model, String apiKey) {
    return Uri.https(
      _googleApiAuthority,
      '/v1beta/models/$model:generateContent',
      {'key': apiKey},
    );
  }

  Future<List<String>> getSavedMotivationalQuotes() async {
    try {
      final quotesPath = await _pathService.motivationalQuotesPath;
      final quotesFile = File(quotesPath);
      if (await quotesFile.exists()) {
        final jsonString = await quotesFile.readAsString();
        if (jsonString.isNotEmpty) {
          return List<String>.from(jsonDecode(jsonString));
        }
      }
    } catch (e) {
      // Abaikan error dan kembalikan list kosong
    }
    return [];
  }

  Future<void> deleteMotivationalQuote(String quoteToDelete) async {
    final quotesPath = await _pathService.motivationalQuotesPath;
    final quotesFile = File(quotesPath);
    final currentQuotes = await getSavedMotivationalQuotes();
    currentQuotes.remove(quoteToDelete);
    await quotesFile.writeAsString(jsonEncode(currentQuotes));
  }

  Future<void> generateAndSaveMotivationalQuotes({int count = 10}) async {
    final settings = await _settingsService.loadSettings();
    final apiKey = await _getActiveApiKey();
    if (apiKey.isEmpty) throw Exception('API Key Gemini tidak aktif.');

    final model = settings.generalModelId;
    final prompt = settings.motivationalQuotePrompt.replaceAll(
      'satu kalimat',
      '$count kalimat',
    );

    final apiUrl = _buildApiUri(model, apiKey);

    final response = await http.post(
      apiUrl,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.9,
          'responseMimeType': 'application/json',
        },
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final textResponse = body['candidates'][0]['content']['parts'][0]['text'];
      final List<dynamic> jsonResponse = jsonDecode(textResponse);
      final newQuotes = List<String>.from(jsonResponse);

      final quotesPath = await _pathService.motivationalQuotesPath;
      final quotesFile = File(quotesPath);
      await quotesFile.writeAsString(jsonEncode(newQuotes));
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['error']?['message'] ?? response.body;
      throw Exception(
        'Gagal mendapatkan respons: ${response.statusCode}\nError: $errorMessage',
      );
    }
  }

  Future<ColorPalette> suggestColorPalette({
    required String theme,
    required String paletteName,
  }) async {
    final settings = await _settingsService.loadSettings();
    final apiKey = await _getActiveApiKey();
    final model = settings.generalModelId;

    if (apiKey.isEmpty) {
      throw Exception('API Key Gemini tidak aktif.');
    }

    final prompt =
        '''
      Buatkan palet warna harmonis untuk UI kartu berdasarkan tema "$theme".
      Aturan Jawaban:
      1. HANYA kembalikan dalam format JSON.
      2. Objek JSON HARUS memiliki tiga kunci: "backgroundColor", "textColor", dan "progressBarColor".
      3. Nilai dari setiap kunci HARUS berupa string hex color (contoh: "#RRGGBB").
      4. Pastikan "textColor" memiliki kontras yang baik dengan "backgroundColor" agar mudah dibaca.
      5. Jangan sertakan penjelasan atau teks lain di luar objek JSON.
      
      Contoh Jawaban:
      {
        "backgroundColor": "#2B2D42",
        "textColor": "#FFFFFF",
        "progressBarColor": "#8D99AE"
      }
      ''';

    final apiUrl = _buildApiUri(model, apiKey);

    try {
      final response = await http.post(
        apiUrl,
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
        final jsonResponse = jsonDecode(textResponse) as Map<String, dynamic>;

        int hexToInt(String hex) {
          hex = hex.toUpperCase().replaceAll("#", "");
          if (hex.length == 6) {
            hex = "FF" + hex;
          }
          return int.parse(hex, radix: 16);
        }

        return ColorPalette(
          name: paletteName,
          backgroundColor: hexToInt(jsonResponse['backgroundColor']),
          textColor: hexToInt(jsonResponse['textColor']),
          progressBarColor: hexToInt(jsonResponse['progressBarColor']),
        );
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

  Future<List<String>> suggestIcon({required String name}) async {
    final settings = await _settingsService.loadSettings();
    final apiKey = await _getActiveApiKey();
    final model = settings.generalModelId;

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

    final apiUrl = _buildApiUri(model, apiKey);

    try {
      final response = await http.post(
        apiUrl,
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

  Future<List<LinkSuggestion>> findSmartLinks({
    required Discussion discussion,
    required List<Map<String, String>> allFiles,
  }) async {
    final settings = await _settingsService.loadSettings();
    final apiKey = await _getActiveApiKey();
    final model = settings.generalModelId;

    if (apiKey.isEmpty) {
      throw Exception('API Key Gemini tidak aktif.');
    }

    final fileListString = allFiles
        .map(
          (f) => "- Judul: \"${f['title']}\", Path: \"${f['relativePath']}\"",
        )
        .join("\n");

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

    final apiUrl = _buildApiUri(model, apiKey);

    try {
      final response = await http.post(
        apiUrl,
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

        return jsonResponse
            .map(
              (item) => LinkSuggestion(
                title: item['title'] ?? 'Tanpa Judul',
                relativePath: item['relativePath'] ?? '',
                score: 1.0,
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

  Future<List<String>> generateDiscussionTitles(String htmlContent) async {
    final settings = await _settingsService.loadSettings();
    final apiKey = await _getActiveApiKey();
    final model = settings.titleGenerationModelId;

    if (apiKey.isEmpty) {
      throw Exception('API Key Gemini tidak aktif.');
    }

    final prompt =
        '''
    Analisis konten HTML berikut dan buatkan 3 sampai 5 rekomendasi judul yang singkat, padat, dan deskriptif dalam Bahasa Indonesia.
    Aturan Jawaban:
    1. HANYA kembalikan dalam format array JSON yang valid.
    2. Setiap elemen dalam array HARUS berupa string judul.
    3. Jangan gunakan tanda kutip di dalam string judul itu sendiri.
    4. Jangan sertakan penjelasan atau teks lain di luar array JSON.

    Konten HTML:
    """
    $htmlContent
    """

    Contoh Jawaban:
    [
      "Judul Rekomendasi Pertama",
      "Judul Alternatif Kedua",
      "Pilihan Judul Ketiga"
    ]
    ''';

    final apiUrl = _buildApiUri(model, apiKey);

    try {
      final response = await http.post(
        apiUrl,
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
          'Gagal mendapatkan judul dari AI: ${response.statusCode}\nError: $errorMessage',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> generateHtmlTemplatePrompt(String themeDescription) async {
    final prompt =
        '''
    Buatkan saya sebuah template HTML5 lengkap dengan tema "$themeDescription".

    ATURAN SANGAT PENTING:
    1.  Gunakan HANYA inline CSS untuk semua styling. JANGAN gunakan tag `<style>` atau file CSS eksternal.
    2.  Di dalam `<body>`, WAJIB ada sebuah `<div>` kosong dengan id `main-container`. Contoh: `<div id="main-container"></div>`. Ini adalah tempat konten akan dimasukkan nanti.
    3.  Pastikan outputnya adalah HANYA kode HTML mentah, tanpa penjelasan tambahan, tanpa ```html, dan tanpa markdown formatting.
    ''';
    return prompt;
  }

  Future<String> generateHtmlTemplate(String themeDescription) async {
    final settings = await _settingsService.loadSettings();
    final apiKey = await _getActiveApiKey();
    final model = settings.contentModelId;

    if (apiKey.isEmpty) {
      throw Exception('API Key Gemini tidak aktif.');
    }

    final prompt = await generateHtmlTemplatePrompt(themeDescription);

    final apiUrl = _buildApiUri(model, apiKey);

    try {
      final response = await http.post(
        apiUrl,
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
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error']?['message'] ?? response.body;
        throw Exception(
          'Gagal menghasilkan template: ${response.statusCode}\nError: $errorMessage',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getChatCompletion(String query, {String? context}) async {
    final settings = await _settingsService.loadSettings();
    final apiKey = await _getActiveApiKey();
    final model = settings.chatModelId;

    if (apiKey.isEmpty) {
      throw Exception(
        'Tidak ada API Key Gemini yang aktif. Silakan atur melalui menu di Dashboard.',
      );
    }

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

    final apiUrl = _buildApiUri(model, apiKey);

    try {
      final response = await http.post(
        apiUrl,
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
    final settings = await _settingsService.loadSettings();
    final apiKey = await _getActiveApiKey();
    final model = settings.contentModelId;

    if (apiKey.isEmpty) {
      throw Exception(
        'Tidak ada API Key Gemini yang aktif. Silakan atur melalui menu di Dashboard.',
      );
    }

    final activePrompt = settings.prompts.firstWhere(
      (p) => p.isActive,
      orElse: () => settings.prompts.first,
    );
    final promptText = activePrompt.content.replaceAll('{topic}', topic);

    final apiUrl = _buildApiUri(model, apiKey);

    try {
      final response = await http.post(
        apiUrl,
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
