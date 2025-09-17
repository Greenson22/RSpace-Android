// lib/features/settings/application/gemini_settings_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/features/settings/domain/models/prompt_model.dart';
import '../domain/models/gemini_settings_model.dart';
import 'package:path/path.dart' as path;

class GeminiSettingsService {
  final PathService _pathService = PathService();

  Future<File> get _settingsFile async {
    final basePath = await _pathService.contentsPath;
    return File(path.join(basePath, 'gemini_settings.json'));
  }

  Future<GeminiSettings> loadSettings() async {
    try {
      final file = await _settingsFile;
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        if (jsonString.isNotEmpty) {
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          return GeminiSettings.fromJson(jsonData);
        }
      }
    } catch (e) {
      debugPrint("Error loading Gemini settings, returning default: $e");
    }
    // Return default settings if file doesn't exist or is invalid
    return _createDefaultSettings();
  }

  Future<void> saveSettings(GeminiSettings settings) async {
    final file = await _settingsFile;
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(settings.toJson()));
  }

  Prompt _getDefaultPrompt() {
    return Prompt(
      id: 'default-prompt',
      name: 'Prompt Standar (Default)',
      content: '''
Buatkan saya konten HTML untuk dimasukkan ke dalam body sebuah website, berdasarkan pembahasan tentang: "{topic}".

Ikuti aturan-aturan berikut dengan ketat:
1. Gunakan HANYA inline CSS untuk semua styling. Jangan gunakan tag <style>.
2. Bungkus seluruh konten dalam satu div utama. Berikan div utama ini style background warna biru muda (misalnya, `style="background-color: #f0f8ff; padding: 20px; border-radius: 8px;"`).
3. Letakkan judul utama di dalam sebuah div tersendiri dengan styling yang menarik (misalnya, `style="background-color: #4a90e2; color: white; padding: 15px; text-align: center; font-size: 24px; border-radius: 5px;"`).
4. Gunakan warna-warni yang harmonis untuk teks paragraf dan sub-judul. Contohnya, gunakan warna seperti `#333` untuk teks biasa, dan warna biru atau hijau tua untuk sub-judul.
5. Jika ada blok kode, gunakan tag `<pre>` dan `<code>`. Beri style pada tag `<pre>` agar terlihat seperti blok kode (misalnya, `style="background-color: #2d2d2d; color: #f8f8f2; padding: 15px; border-radius: 5px; overflow-x: auto; font-family: monospace;"`). Di dalam tag `<code>`, gunakan tag `<span>` dengan warna berbeda untuk menyorot keyword, string, dan komentar jika memungkinkan, sesuai bahasa pemrogramannya.
6. Sertakan simbol-simbol atau emoji yang relevan (contoh: 💡, 🚀, ✅) untuk memperkaya konten secara visual di tempat yang sesuai.
7. Pastikan outputnya adalah HANYA kode HTML, tanpa penjelasan tambahan di luar kode.
''',
      isActive: true,
      isDefault: true,
    );
  }

  GeminiSettings _createDefaultSettings() {
    return GeminiSettings(prompts: [_getDefaultPrompt()]);
  }
}
