// lib/features/settings/application/services/gemini_service_flutter_gemini.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:my_aplication/features/progress/domain/models/color_palette_model.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/features/content_management/domain/models/discussion_model.dart';
import 'package:my_aplication/features/link_maintenance/domain/models/link_suggestion_model.dart';
import '../gemini_settings_service.dart';

class GeminiServiceFlutterGemini {
  final GeminiSettingsService _settingsService = GeminiSettingsService();
  final PathService _pathService = PathService();

  /// Menginisialisasi Gemini dengan API Key yang sedang aktif.
  Future<void> _initializeGeminiWithActiveKey() async {
    final settings = await _settingsService.loadSettings();
    String apiKey = '';
    try {
      apiKey = settings.apiKeys.firstWhere((k) => k.isActive).key;
    } catch (e) {
      // Biarkan API key kosong jika tidak ada yang aktif
    }
    Gemini.init(apiKey: apiKey);
  }

  // --- File Operations for Motivational Quotes ---

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

  // --- Gemini API Calls ---

  Future<void> generateAndSaveMotivationalQuotes({int count = 10}) async {
    await _initializeGeminiWithActiveKey();
    final settings = await _settingsService.loadSettings();
    final gemini = Gemini.instance;
    final modelName = settings.generalModelId;

    final prompt = settings.motivationalQuotePrompt
        .replaceAll('satu kalimat', '$count kalimat')
        .replaceAll('json.', 'format JSON.');

    try {
      final result = await gemini.text(prompt, modelName: modelName);
      final textResponse = result?.output;

      if (textResponse != null) {
        final cleanedResponse = textResponse
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final List<dynamic> jsonResponse = jsonDecode(cleanedResponse);
        final newQuotes = List<String>.from(jsonResponse);

        final quotesPath = await _pathService.motivationalQuotesPath;
        final quotesFile = File(quotesPath);
        await quotesFile.writeAsString(jsonEncode(newQuotes));
      } else {
        throw Exception('Gagal mendapatkan respons dari AI (respons kosong).');
      }
    } catch (e) {
      if (e.toString().contains('API key is not valid')) {
        throw Exception(
          'API Key Gemini tidak aktif atau tidak valid. Silakan atur di Pengaturan.',
        );
      }
      rethrow;
    }
  }

  Future<List<LinkSuggestion>> findSmartLinks({
    required Discussion discussion,
    required List<Map<String, String>> allFiles,
  }) async {
    await _initializeGeminiWithActiveKey();
    final settings = await _settingsService.loadSettings();
    final gemini = Gemini.instance;
    final modelName = settings.generalModelId;

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

      Aturan Jawaban SANGAT PENTING:
      1.  Jawaban Anda HARUS HANYA berupa array JSON yang valid.
      2.  Setiap objek dalam array HARUS memiliki kunci "title" dan "relativePath".
      3.  Pastikan nilai "relativePath" persis sama dengan yang ada di daftar.
      4.  Jangan sertakan penjelasan atau teks lain di luar array JSON.

      Contoh Jawaban:
      [
        {"title": "Judul File Pilihan 1", "relativePath": "TopikA/SubjekB/file1.html"},
        {"title": "Judul File Pilihan 2", "relativePath": "TopikC/SubjekD/file2.html"}
      ]
      ''';

    try {
      final result = await gemini.text(prompt, modelName: modelName);
      final textResponse = result?.output;

      if (textResponse != null) {
        final cleanedResponse = textResponse
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final List<dynamic> jsonResponse = jsonDecode(cleanedResponse);
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
        throw Exception('Gagal mendapatkan respons dari AI (respons kosong).');
      }
    } catch (e) {
      if (e.toString().contains('API key is not valid')) {
        throw Exception(
          'API Key Gemini tidak aktif atau tidak valid. Silakan atur di Pengaturan.',
        );
      }
      rethrow;
    }
  }

  Future<List<String>> generateDiscussionTitles(String htmlContent) async {
    await _initializeGeminiWithActiveKey();
    final settings = await _settingsService.loadSettings();
    final gemini = Gemini.instance;
    final modelName = settings.titleGenerationModelId;

    final prompt =
        '''
    Analisis konten HTML berikut dan buatkan 3 sampai 5 rekomendasi judul yang singkat, padat, dan deskriptif dalam Bahasa Indonesia.
    Aturan Jawaban SANGAT PENTING:
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
    try {
      final result = await gemini.text(prompt, modelName: modelName);
      final textResponse = result?.output;

      if (textResponse != null) {
        final cleanedResponse = textResponse
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final List<dynamic> jsonResponse = jsonDecode(cleanedResponse);
        return List<String>.from(jsonResponse);
      } else {
        throw Exception('Gagal mendapatkan respons dari AI (respons kosong).');
      }
    } catch (e) {
      if (e.toString().contains('API key is not valid')) {
        throw Exception(
          'API Key Gemini tidak aktif atau tidak valid. Silakan atur di Pengaturan.',
        );
      }
      rethrow;
    }
  }

  Future<String> generateHtmlContent(String topic) async {
    await _initializeGeminiWithActiveKey();
    final settings = await _settingsService.loadSettings();
    final gemini = Gemini.instance;
    final modelName = settings.contentModelId;

    final activePrompt = settings.prompts.firstWhere(
      (p) => p.isActive,
      orElse: () => settings.prompts.first,
    );
    final promptText = activePrompt.content.replaceAll('{topic}', topic);

    try {
      final result = await gemini.text(promptText, modelName: modelName);
      final textResponse = result?.output;

      if (textResponse != null) {
        return textResponse
            .replaceAll('```html', '')
            .replaceAll('```', '')
            .trim();
      } else {
        throw Exception('Gagal mendapatkan respons dari AI (respons kosong).');
      }
    } catch (e) {
      if (e.toString().contains('API key is not valid')) {
        throw Exception(
          'API Key Gemini tidak aktif atau tidak valid. Silakan atur di Pengaturan.',
        );
      }
      rethrow;
    }
  }

  // Sisa fungsi tidak berubah (generateQuizQuestions, suggestColorPalette, etc.)
  Future<String> generateHtmlTemplate(String themeDescription) async {
    await _initializeGeminiWithActiveKey();
    final settings = await _settingsService.loadSettings();
    final gemini = Gemini.instance;
    final modelName = settings.contentModelId;

    final prompt =
        '''
    Buatkan saya sebuah template HTML5 lengkap dengan tema "$themeDescription".

    ATURAN SANGAT PENTING:
    1.  Gunakan HANYA inline CSS untuk semua styling. JANGAN gunakan tag `<style>` atau file CSS eksternal.
    2.  Di dalam `<body>`, WAJIB ada sebuah `<div>` kosong dengan id `main-container`. Contoh: `<div id="main-container"></div>`. Ini adalah tempat konten akan dimasukkan nanti.
    3.  Pastikan outputnya adalah HANYA kode HTML mentah, tanpa penjelasan tambahan, tanpa ```html, dan tanpa markdown formatting.
    ''';

    try {
      final result = await gemini.text(prompt, modelName: modelName);
      final textResponse = result?.output;

      if (textResponse != null) {
        return textResponse
            .replaceAll('```html', '')
            .replaceAll('```', '')
            .trim();
      } else {
        throw Exception('Gagal mendapatkan respons dari AI (respons kosong).');
      }
    } catch (e) {
      if (e.toString().contains('API key is not valid')) {
        throw Exception(
          'API Key Gemini tidak aktif atau tidak valid. Silakan atur di Pengaturan.',
        );
      }
      rethrow;
    }
  }

  Future<List<QuizQuestion>> generateQuizQuestions({
    required String context,
    required int questionCount,
    required QuizDifficulty difficulty,
  }) async {
    await _initializeGeminiWithActiveKey();
    final settings = await _settingsService.loadSettings();
    final gemini = Gemini.instance;
    final modelName = settings.quizModelId;

    final prompt =
        '''
    Anda adalah AI pembuat kuis. Berdasarkan konteks materi berikut:
    ---
    $context
    ---

    Buatkan $questionCount pertanyaan kuis pilihan ganda yang relevan dengan tingkat kesulitan: ${difficulty.displayName}.
    Untuk tingkat kesulitan "HOTS", buatlah pertanyaan yang membutuhkan analisis atau penerapan konsep, bukan hanya ingatan.

    Aturan Jawaban SANGAT PENTING:
    1.  Jawaban Anda HARUS HANYA berupa array JSON yang valid, tidak ada teks lain.
    2.  Setiap objek dalam array mewakili satu pertanyaan dan HARUS memiliki kunci: "questionText", "options", dan "correctAnswerIndex".
    3.  "questionText" harus berupa string.
    4.  "options" harus berupa array berisi 4 string pilihan jawaban.
    5.  "correctAnswerIndex" harus berupa integer (0-3) yang menunjuk ke jawaban yang benar.
    6.  Jangan sertakan markdown seperti ```json di awal atau akhir.

    Contoh Jawaban:
    [
      {
        "questionText": "Apa itu widget dalam Flutter?",
        "options": ["Blok bangunan UI", "Tipe variabel", "Fungsi database", "Permintaan jaringan"],
        "correctAnswerIndex": 0
      }
    ]
    ''';

    try {
      final result = await gemini.text(prompt, modelName: modelName);
      final textResponse = result?.output;

      if (textResponse != null) {
        final cleanedResponse = textResponse
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final List<dynamic> jsonResponse = jsonDecode(cleanedResponse);

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
        throw Exception('Gagal mendapatkan respons dari AI (respons kosong).');
      }
    } catch (e) {
      if (e.toString().contains('API key is not valid')) {
        throw Exception(
          'API Key Gemini tidak aktif atau tidak valid. Silakan atur di Pengaturan.',
        );
      }
      rethrow;
    }
  }

  Future<ColorPalette> suggestColorPalette({
    required String theme,
    required String paletteName,
  }) async {
    await _initializeGeminiWithActiveKey();
    final settings = await _settingsService.loadSettings();
    final gemini = Gemini.instance;
    final modelName = settings.generalModelId;

    final prompt =
        '''
      Buatkan palet warna harmonis untuk UI kartu berdasarkan tema "$theme".
      Aturan Jawaban SANGAT PENTING:
      1. Jawaban Anda HARUS HANYA berupa objek JSON yang valid, tidak ada teks lain.
      2. Objek JSON HARUS memiliki tiga kunci: "backgroundColor", "textColor", dan "progressBarColor".
      3. Nilai dari setiap kunci HARUS berupa string hex color (contoh: "#RRGGBB").
      4. Pastikan "textColor" memiliki kontras yang baik dengan "backgroundColor" agar mudah dibaca.
      5. Jangan sertakan markdown seperti ```json di awal atau akhir.

      Contoh Jawaban:
      {
        "backgroundColor": "#2B2D42",
        "textColor": "#FFFFFF",
        "progressBarColor": "#8D99AE"
      }
      ''';

    try {
      final result = await gemini.text(prompt, modelName: modelName);
      final textResponse = result?.output;

      if (textResponse != null) {
        final cleanedResponse = textResponse
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final jsonResponse =
            jsonDecode(cleanedResponse) as Map<String, dynamic>;

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
        throw Exception('Gagal mendapatkan respons dari AI (respons kosong).');
      }
    } catch (e) {
      if (e.toString().contains('API key is not valid')) {
        throw Exception(
          'API Key Gemini tidak aktif atau tidak valid. Silakan atur di Pengaturan.',
        );
      }
      rethrow;
    }
  }

  Future<List<String>> suggestIcon({required String name}) async {
    await _initializeGeminiWithActiveKey();
    final settings = await _settingsService.loadSettings();
    final gemini = Gemini.instance;
    final modelName = settings.generalModelId;

    final prompt =
        '''
Berikan 5 rekomendasi emoji unicode yang paling relevan untuk item bernama "$name".
Aturan Jawaban SANGAT PENTING:
1. Jawaban Anda HARUS HANYA berupa array JSON yang valid, tidak ada teks lain.
2. Setiap elemen dalam array HARUS berupa string emoji.
3. Jangan sertakan markdown seperti ```json di awal atau akhir.

Contoh Jawaban:
["💡", "📚", "⚙️", "❤️", "⭐"]
''';

    try {
      final result = await gemini.text(prompt, modelName: modelName);
      final textResponse = result?.output;

      if (textResponse != null) {
        final cleanedResponse = textResponse
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final List<dynamic> jsonResponse = jsonDecode(cleanedResponse);
        return List<String>.from(jsonResponse);
      } else {
        throw Exception('Gagal mendapatkan respons dari AI (respons kosong).');
      }
    } catch (e) {
      if (e.toString().contains('API key is not valid')) {
        throw Exception(
          'API Key Gemini tidak aktif atau tidak valid. Silakan atur di Pengaturan.',
        );
      }
      rethrow;
    }
  }

  Future<String?> getChatCompletion(List<Content> contents) async {
    await _initializeGeminiWithActiveKey();
    final settings = await _settingsService.loadSettings();
    final gemini = Gemini.instance;
    final modelName = settings.chatModelId;

    try {
      final result = await gemini.chat(contents, modelName: modelName);
      final textResponse = result?.output;

      if (textResponse != null) {
        return textResponse;
      } else {
        throw Exception('Gagal mendapatkan respons dari AI (respons kosong).');
      }
    } catch (e) {
      if (e.toString().contains('API key is not valid')) {
        throw Exception(
          'API Key Gemini tidak aktif atau tidak valid. Silakan atur di Pengaturan.',
        );
      }
      rethrow;
    }
  }
}
