import 'dart:convert';
import 'package:flutter_gemini/flutter_gemini.dart';
// ==> PERBAIKAN DI SINI <==
import '../gemini_settings_service.dart';

class GeminiServiceFlutterGemini {
  final GeminiSettingsService _settingsService = GeminiSettingsService();

  /// Menginisialisasi Gemini dengan API Key yang sedang aktif.
  Future<void> _initializeGeminiWithActiveKey() async {
    final settings = await _settingsService.loadSettings();
    String apiKey = '';
    try {
      // Ambil kunci yang ditandai aktif dari pengaturan
      apiKey = settings.apiKeys.firstWhere((k) => k.isActive).key;
    } catch (e) {
      // Biarkan API key kosong jika tidak ada yang aktif
    }
    // Inisialisasi Gemini dengan kunci yang ditemukan
    Gemini.init(apiKey: apiKey);
  }

  /// Memberikan saran ikon emoji berdasarkan nama/topik yang diberikan.
  Future<List<String>> suggestIcon({required String name}) async {
    // Selalu inisialisasi ulang untuk memastikan kunci API terbaru yang digunakan
    await _initializeGeminiWithActiveKey();

    final gemini = Gemini.instance;

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
      // Menggunakan metode .text() dari package flutter_gemini
      final result = await gemini.text(prompt);
      final textResponse = result?.output;

      if (textResponse != null) {
        // Membersihkan respons jika terbungkus dalam format markdown code block
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
      // Memberikan pesan error yang lebih spesifik jika masalahnya adalah API Key
      if (e.toString().contains('API key is not valid')) {
        throw Exception(
          'API Key Gemini tidak aktif atau tidak valid. Silakan atur di Pengaturan.',
        );
      }
      // Lemparkan kembali error lain untuk ditangani oleh UI
      rethrow;
    }
  }
}
