// lib/features/settings/application/services/gemini_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/features/content_management/domain/services/discussion_service.dart';
import 'package:my_aplication/features/progress/domain/models/color_palette_model.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';
import '../../domain/models/api_key_model.dart';
import '../../../content_management/domain/models/discussion_model.dart';
import '../../../link_maintenance/domain/models/link_suggestion_model.dart';
import '../../../../core/services/storage_service.dart';

class GeminiService {
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final DiscussionService _discussionService = DiscussionService();
  // ==> 1. TAMBAHKAN INSTANCE PATHSERVICE
  final PathService _pathService = PathService();

  Future<String> _getActiveApiKey() async {
    final List<ApiKey> keys = await _prefsService.loadApiKeys();
    try {
      final activeKey = keys.firstWhere((k) => k.isActive);
      return activeKey.key;
    } catch (e) {
      return '';
    }
  }

  // ==> 2. FUNGSI INI DIUBAH TOTAL
  /// Menghasilkan atau mengambil satu kalimat motivasi belajar.
  Future<String> getMotivationalQuote() async {
    // Daftar fallback jika semua gagal
    const fallbackQuotes = [
      'Mulailah dari mana kau berada. Gunakan apa yang kau punya. Lakukan apa yang kau bisa.',
      'Pendidikan adalah senjata paling ampuh untuk mengubah dunia.',
      'Satu-satunya sumber pengetahuan adalah pengalaman.',
      'Belajar adalah proses seumur hidup, bukan hanya di sekolah.',
    ];
    final random = Random();

    // Membaca kutipan yang sudah ada
    List<String> existingQuotes = [];
    final quotesPath = await _pathService.motivationalQuotesPath;
    final quotesFile = File(quotesPath);
    try {
      if (await quotesFile.exists()) {
        final jsonString = await quotesFile.readAsString();
        if (jsonString.isNotEmpty) {
          existingQuotes = List<String>.from(jsonDecode(jsonString));
        }
      } else {
        await quotesFile.create(recursive: true);
        await quotesFile.writeAsString('[]');
      }
    } catch (e) {
      // Abaikan jika ada error pembacaan file
    }

    final apiKey = await _getActiveApiKey();
    if (apiKey.isEmpty) {
      if (existingQuotes.isNotEmpty) {
        return existingQuotes[random.nextInt(existingQuotes.length)];
      }
      return fallbackQuotes[random.nextInt(fallbackQuotes.length)];
    }

    final model =
        await _prefsService.loadGeminiGeneralModel() ?? 'gemini-1.5-flash';
    final apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

    const prompt =
        'Berikan saya satu kalimat motivasi singkat tentang belajar atau pengetahuan dalam Bahasa Indonesia. Kalimat harus inspiratif dan tidak lebih dari 20 kata. Jangan gunakan tanda kutip di awal dan akhir kalimat.';

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
          'generationConfig': {'temperature': 0.9},
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
              final newQuote = parts[0]['text'] as String? ?? '';
              if (newQuote.isNotEmpty && !existingQuotes.contains(newQuote)) {
                existingQuotes.add(newQuote);
                // Jaga agar daftar tidak lebih dari 5
                if (existingQuotes.length > 5) {
                  existingQuotes.removeAt(0); // Hapus yang paling lama
                }
                await quotesFile.writeAsString(jsonEncode(existingQuotes));
              }
              return newQuote;
            }
          }
        }
      }
    } catch (e) {
      // Jika error, kembalikan dari cache atau fallback
      if (existingQuotes.isNotEmpty) {
        return existingQuotes[random.nextInt(existingQuotes.length)];
      }
    }

    // Fallback terakhir
    return fallbackQuotes[random.nextInt(fallbackQuotes.length)];
  }

  Future<ColorPalette> suggestColorPalette({
    required String theme,
    required String paletteName,
  }) async {
    final apiKey = await _getActiveApiKey();
    final model =
        await _prefsService.loadGeminiGeneralModel() ?? 'gemini-1.5-flash';

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

  Future<List<QuizQuestion>> generateQuizFromText(
    String customTopic, {
    int questionCount = 10,
    QuizDifficulty difficulty = QuizDifficulty.medium,
  }) async {
    final apiKey = await _getActiveApiKey();
    final model =
        await _prefsService.loadGeminiQuizModel() ?? 'gemini-1.5-flash';

    if (apiKey.isEmpty) {
      throw Exception('API Key Gemini tidak aktif.');
    }

    if (customTopic.trim().isEmpty) {
      throw Exception('Materi kuis tidak boleh kosong.');
    }

    final prompt =
        '''
    Anda adalah AI pembuat kuis. Berdasarkan materi berikut:
    ---
    $customTopic
    ---
    
    Buatkan $questionCount pertanyaan kuis pilihan ganda yang relevan dengan tingkat kesulitan: ${difficulty.displayName}.
    Untuk tingkat kesulitan "HOTS", buatlah pertanyaan yang membutuhkan analisis atau penerapan konsep, bukan hanya ingatan.
    
    Aturan Jawaban:
    1.  HANYA kembalikan dalam format array JSON yang valid.
    2.  Setiap objek dalam array mewakili satu pertanyaan dan HARUS memiliki kunci: "questionText", "options", dan "correctAnswerIndex".
    3.  "questionText" harus berupa string.
    4.  "options" harus berupa array berisi 4 string pilihan jawaban.
    5.  "correctAnswerIndex" harus berupa integer (0-3) yang menunjuk ke jawaban yang benar.
    6.  Jangan sertakan penjelasan atau teks lain di luar array JSON.

    Contoh Jawaban:
    [
      {
        "questionText": "Apa itu widget dalam Flutter?",
        "options": ["Blok bangunan UI", "Tipe variabel", "Fungsi database", "Permintaan jaringan"],
        "correctAnswerIndex": 0
      }
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
          'generationConfig': {'responseMimeType': 'application/json'},
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final textResponse =
            body['candidates'][0]['content']['parts'][0]['text'];
        final List<dynamic> jsonResponse = jsonDecode(textResponse);

        return jsonResponse.map((item) {
          final optionsList = (item['options'] as List<dynamic>).cast<String>();
          final correctIndex = item['correctAnswerIndex'] as int;
          final options = List.generate(optionsList.length, (i) {
            return QuizOption(
              text: optionsList[i],
              isCorrect: i == correctIndex,
            );
          });
          return QuizQuestion(
            questionText: item['questionText'] as String,
            options: options,
          );
        }).toList();
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

  Future<List<QuizQuestion>> generateQuizFromSubject(
    String subjectJsonPath, {
    int questionCount = 10,
    QuizDifficulty difficulty = QuizDifficulty.medium,
  }) async {
    final discussions = await _discussionService.loadDiscussions(
      subjectJsonPath,
    );
    final contentBuffer = StringBuffer();
    for (final discussion in discussions) {
      if (!discussion.finished) {
        contentBuffer.writeln('- Judul: ${discussion.discussion}');
        for (final point in discussion.points) {
          contentBuffer.writeln('  - Poin: ${point.pointText}');
        }
      }
    }

    if (contentBuffer.isEmpty) {
      throw Exception(
        'Subject ini tidak memiliki konten aktif untuk dibuatkan kuis.',
      );
    }

    return generateQuizFromText(
      contentBuffer.toString(),
      questionCount: questionCount,
      difficulty: difficulty,
    );
  }
}
