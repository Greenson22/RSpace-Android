// lib/features/settings/application/services/gemini_service_flutter_gemini.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:my_aplication/features/progress/domain/models/color_palette_model.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';
import '../gemini_settings_service.dart';

class GeminiServiceFlutterGemini {
  final GeminiSettingsService _settingsService = GeminiSettingsService();

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

  /// Membuat pertanyaan kuis langsung dari konteks yang diberikan.
  Future<List<QuizQuestion>> generateQuizQuestions({
    required String context,
    required int questionCount,
    required QuizDifficulty difficulty,
  }) async {
    await _initializeGeminiWithActiveKey();
    final settings = await _settingsService.loadSettings();
    final gemini = Gemini.instance;
    final modelName =
        settings.quizModelId; // Menggunakan model khusus untuk kuis

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
      // ==> PERBAIKAN: Menghapus `generationConfig`
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

  /// Memberikan saran palet warna berdasarkan tema menggunakan flutter_gemini.
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
      // ==> PERBAIKAN: Menghapus `generationConfig`
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

  /// Memberikan saran ikon emoji berdasarkan nama/topik yang diberikan.
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
      // ==> PERBAIKAN: Menghapus `generationConfig`
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

  /// Mendapatkan balasan chat dari model Gemini menggunakan package flutter_gemini.
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
