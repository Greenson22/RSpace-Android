// lib/core/services/gemini_storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../features/settings/domain/models/api_key_model.dart';
import '../../features/settings/domain/models/prompt_model.dart';

class GeminiService {
  static const String _geminiApiKey_old = 'gemini_api_key';
  static const String _geminiApiKeys = 'gemini_api_keys_list';
  static const String _geminiPrompts = 'gemini_prompts_list';
  static const String _geminiContentModelKey = 'gemini_model';
  static const String _geminiChatModelKey = 'gemini_chat_model';
  static const String _geminiGeneralModelKey = 'gemini_general_model';
  // ==> TAMBAHKAN KEY BARU <==
  static const String _geminiQuizModelKey = 'gemini_quiz_model';

  Future<void> saveApiKeys(List<ApiKey> keys) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = encodeApiKeys(keys);
    await prefs.setString(_geminiApiKeys, encodedData);
  }

  Future<List<ApiKey>> loadApiKeys() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(_geminiApiKeys)) {
      final String? encodedData = prefs.getString(_geminiApiKeys);
      return decodeApiKeys(encodedData ?? '[]');
    }

    if (prefs.containsKey(_geminiApiKey_old)) {
      final String? oldKey = prefs.getString(_geminiApiKey_old);
      if (oldKey != null && oldKey.isNotEmpty) {
        final migratedKey = ApiKey(
          id: const Uuid().v4(),
          name: 'Kunci Lama (Default)',
          key: oldKey,
          isActive: true,
        );
        final List<ApiKey> keys = [migratedKey];
        await saveApiKeys(keys);
        await prefs.remove(_geminiApiKey_old);
        return keys;
      }
    }

    return [];
  }

  Future<void> saveGeminiContentModel(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiContentModelKey, modelId);
  }

  Future<String?> loadGeminiContentModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiContentModelKey);
  }

  Future<void> saveGeminiChatModel(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiChatModelKey, modelId);
  }

  Future<String?> loadGeminiChatModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiChatModelKey);
  }

  Future<void> saveGeminiGeneralModel(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiGeneralModelKey, modelId);
  }

  Future<String?> loadGeminiGeneralModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiGeneralModelKey);
  }

  // ==> TAMBAHKAN FUNGSI BARU UNTUK MODEL KUIS <==
  Future<void> saveGeminiQuizModel(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_geminiQuizModelKey, modelId);
  }

  Future<String?> loadGeminiQuizModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_geminiQuizModelKey);
  }

  Future<void> savePrompts(List<Prompt> prompts) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = encodePrompts(prompts);
    await prefs.setString(_geminiPrompts, encodedData);
  }

  Future<List<Prompt>> loadPrompts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_geminiPrompts);
    return decodePrompts(encodedData ?? '[]');
  }

  Future<Prompt> getActivePrompt() async {
    List<Prompt> prompts = await loadPrompts();
    if (prompts.isEmpty) {
      return _getDefaultPrompt();
    }
    try {
      return prompts.firstWhere((p) => p.isActive);
    } catch (e) {
      final defaultOrFirst = prompts.firstWhere(
        (p) => p.isDefault,
        orElse: () => prompts.first,
      );
      defaultOrFirst.isActive = true;
      await savePrompts(prompts);
      return defaultOrFirst;
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
}
