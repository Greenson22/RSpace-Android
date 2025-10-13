// lib/features/settings/application/services/gemini_service_flutter_gemini.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:my_aplication/features/progress/domain/models/color_palette_model.dart';
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

  /// Memberikan saran palet warna berdasarkan tema menggunakan flutter_gemini.
  Future<ColorPalette> suggestColorPalette({
    required String theme,
    required String paletteName,
  }) async {
    await _initializeGeminiWithActiveKey();
    final settings = await _settingsService.loadSettings();
    final gemini = Gemini.instance;
    final modelName = settings.generalModelId;

    // ==> PERBAIKAN PROMPT DI SINI <==
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
      // ==> PERBAIKAN: Hapus parameter `generationConfig` <==
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

    // ==> PERBAIKAN PROMPT DI SINI <==
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
      // ==> PERBAIKAN: Hapus parameter `generationConfig` <==
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
