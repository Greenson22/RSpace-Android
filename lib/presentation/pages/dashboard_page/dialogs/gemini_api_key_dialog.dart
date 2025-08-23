// lib/presentation/pages/dashboard_page/dialogs/gemini_api_key_dialog.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/services/shared_preferences_service.dart';

// Kelas helper untuk data model
class GeminiModelInfo {
  final String name;
  final String id;

  const GeminiModelInfo({required this.name, required this.id});
}

void showGeminiApiKeyDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const GeminiApiKeyDialog(),
  );
}

class GeminiApiKeyDialog extends StatefulWidget {
  const GeminiApiKeyDialog({super.key});

  @override
  State<GeminiApiKeyDialog> createState() => _GeminiApiKeyDialogState();
}

class _GeminiApiKeyDialogState extends State<GeminiApiKeyDialog> {
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  late TextEditingController _apiKeyController;
  bool _isLoading = true;
  bool _obscureText = true;
  String? _selectedModelId;

  // Daftar model AI berdasarkan gambar yang Anda berikan
  final List<GeminiModelInfo> _models = const [
    GeminiModelInfo(name: 'Gemini 2.5 Pro', id: 'gemini-2.5-pro'),
    GeminiModelInfo(name: 'Gemini 2.5 Flash', id: 'gemini-2.5-flash'),
    GeminiModelInfo(name: 'Gemini 2.5 Flash-Lite', id: 'gemini-2.5-flash-lite'),
    GeminiModelInfo(name: 'Gemini 2.0 Flash', id: 'gemini-2.0-flash'),
    GeminiModelInfo(name: 'Gemma 3 27B', id: 'gemma-3-27b-it'),
    GeminiModelInfo(name: 'Gemma 3 12B', id: 'gemma-3-12b-it'),
    GeminiModelInfo(name: 'Gemma 3 4B', id: 'gemma-3-4b-it'),
    GeminiModelInfo(name: 'Gemma 3n E4B', id: 'gemma-3n-e4b-it'),
    GeminiModelInfo(name: 'Gemma 3n E2B', id: 'gemma-3n-e2b-it'),
  ];

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final apiKey = await _prefsService.loadGeminiApiKey();
    final modelId = await _prefsService.loadGeminiModel();
    if (mounted) {
      setState(() {
        _apiKeyController.text = apiKey ?? '';
        // Set model yang tersimpan, atau default ke model pertama jika belum ada
        _selectedModelId = modelId ?? _models.first.id;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (_apiKeyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API Key tidak boleh kosong.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await _prefsService.saveGeminiApiKey(_apiKeyController.text.trim());
    if (_selectedModelId != null) {
      await _prefsService.saveGeminiModel(_selectedModelId!);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan Gemini berhasil disimpan.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Konfigurasi Gemini AI'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  const TextSpan(
                    text:
                        'API Key diperlukan untuk menggunakan fitur AI. Dapatkan kunci gratis di ',
                  ),
                  TextSpan(
                    text: 'Google AI Studio',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        launchUrl(
                          Uri.parse('https://aistudio.google.com/app/apikey'),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              DropdownButtonFormField<String>(
                value: _selectedModelId,
                decoration: const InputDecoration(
                  labelText: 'Pilih Model AI',
                  border: OutlineInputBorder(),
                ),
                items: _models.map((model) {
                  return DropdownMenuItem<String>(
                    value: model.id,
                    child: Text(model.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedModelId = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apiKeyController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'API Key Gemini',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _saveSettings, child: const Text('Simpan')),
      ],
    );
  }
}
