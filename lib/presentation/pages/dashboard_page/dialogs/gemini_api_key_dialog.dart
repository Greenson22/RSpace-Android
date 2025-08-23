// lib/presentation/pages/dashboard_page/dialogs/gemini_api_key_dialog.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/services/shared_preferences_service.dart';

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

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final apiKey = await _prefsService.loadGeminiApiKey();
    if (mounted) {
      setState(() {
        _apiKeyController.text = apiKey ?? '';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey() async {
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API Key Gemini berhasil disimpan.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Konfigurasi API Key Gemini'),
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
                        'API Key diperlukan untuk menggunakan fitur "Generate Content with AI". Anda bisa mendapatkan API Key secara gratis di ',
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
            else
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _saveApiKey, child: const Text('Simpan')),
      ],
    );
  }
}
