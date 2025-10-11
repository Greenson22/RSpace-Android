import 'dart:convert';
import 'package:flutter_gemini/flutter_gemini.dart';
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

  /// Memberikan saran ikon emoji berdasarkan nama/topik yang diberikan.
  Future<List<String>> suggestIcon({required String name}) async {
    await _initializeGeminiWithActiveKey();
    final settings = await _settingsService.loadSettings();
    // ==> PERUBAHAN 1: Gunakan model yang dipilih untuk tugas umum <==
    final gemini = Gemini.instance;
    final modelName = settings.generalModelId;

    final prompt =
        '''
Berikan 5 rekomendasi emoji unicode yang paling relevan untuk item bernama "$name".
Aturan Jawaban:
1. HANYA kembalikan dalam format array JSON yang valid.
2. Setiap elemen dalam array HARUS berupa string emoji.
3. Jangan sertakan penjelasan atau teks lain di luar array JSON.

Contoh Jawaban:
["💡", "📚", "⚙️", "❤️", "⭐"]
''';

    try {
      // ==> PERUBAHAN 2: Tambahkan parameter modelName saat memanggil text() <==
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
    // ==> PERUBAHAN 3: Gunakan model yang dipilih untuk chat <==
    final gemini = Gemini.instance;
    final modelName = settings.chatModelId;

    try {
      // ==> PERUBAHAN 4: Tambahkan parameter modelName saat memanggil chat() <==
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
