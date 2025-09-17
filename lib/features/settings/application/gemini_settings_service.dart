// lib/features/settings/application/gemini_settings_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
          var settings = GeminiSettings.fromJson(jsonData);

          // ==> LOGIKA BARU: Gabungkan model default dengan model kustom <==
          final defaultModels = await _loadDefaultModelsFromJson();
          final customModels = settings.models
              .where((m) => !m.isDefault)
              .toList();
          final combinedModels = [...defaultModels, ...customModels];

          settings = settings.copyWith(models: combinedModels);

          settings = _validateSelectedModels(settings);

          return settings;
        }
      }
    } catch (e) {
      debugPrint("Error loading Gemini settings, returning default: $e");
    }
    return _createDefaultSettings();
  }

  GeminiSettings _validateSelectedModels(GeminiSettings settings) {
    final availableModelIds = settings.models.map((m) => m.modelId).toSet();
    if (availableModelIds.isEmpty) return settings;

    final firstAvailableModel = settings.models.first.modelId;

    return settings.copyWith(
      generalModelId: availableModelIds.contains(settings.generalModelId)
          ? settings.generalModelId
          : firstAvailableModel,
      contentModelId: availableModelIds.contains(settings.contentModelId)
          ? settings.contentModelId
          : firstAvailableModel,
      chatModelId: availableModelIds.contains(settings.chatModelId)
          ? settings.chatModelId
          : firstAvailableModel,
      quizModelId: availableModelIds.contains(settings.quizModelId)
          ? settings.quizModelId
          : firstAvailableModel,
      titleGenerationModelId:
          availableModelIds.contains(settings.titleGenerationModelId)
          ? settings.titleGenerationModelId
          : firstAvailableModel,
    );
  }

  Future<void> saveSettings(GeminiSettings settings) async {
    final file = await _settingsFile;
    // Hanya simpan model yang bukan default
    final customModelsOnly = settings.models
        .where((m) => !m.isDefault)
        .toList();
    final settingsToSave = settings.copyWith(models: customModelsOnly);

    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(settingsToSave.toJson()));
  }

  Future<List<GeminiModelInfo>> _loadDefaultModelsFromJson() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/gemini_models.json',
      );
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => GeminiModelInfo.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint("Error loading default models from JSON: $e");
      return [
        GeminiModelInfo(
          name: 'Gemini 1.5 Pro (Fallback)',
          modelId: 'gemini-1.5-pro-latest',
          isDefault: true,
        ),
      ];
    }
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

  Future<GeminiSettings> _createDefaultSettings() async {
    return GeminiSettings(
      prompts: [_getDefaultPrompt()],
      models: await _loadDefaultModelsFromJson(),
    );
  }
}
