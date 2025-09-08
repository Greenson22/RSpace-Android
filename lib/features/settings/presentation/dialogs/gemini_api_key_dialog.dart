// lib/presentation/pages/dashboard_page/dialogs/gemini_api_key_dialog.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/api_key_model.dart';
import '../../../../core/services/storage_service.dart';

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
  List<ApiKey> _apiKeys = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final keys = await _prefsService.loadApiKeys();
    if (mounted) {
      setState(() {
        _apiKeys = keys;
        _isLoading = false;
      });
    }
  }

  Future<void> _setActiveKey(ApiKey keyToActivate) async {
    setState(() {
      for (var key in _apiKeys) {
        key.isActive = (key.id == keyToActivate.id);
      }
    });
    await _prefsService.saveApiKeys(_apiKeys);
  }

  Future<void> _deleteKey(ApiKey keyToDelete) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Anda yakin ingin menghapus kunci "${keyToDelete.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _apiKeys.removeWhere((key) => key.id == keyToDelete.id);
        if (keyToDelete.isActive && _apiKeys.isNotEmpty) {
          if (!_apiKeys.any((k) => k.isActive)) {
            _apiKeys.first.isActive = true;
          }
        }
      });
      await _prefsService.saveApiKeys(_apiKeys);
    }
  }

  Future<void> _addNewKey() async {
    final newKey = await _showAddOrEditKeyDialog();
    if (newKey != null) {
      if (_apiKeys.isEmpty) {
        newKey.isActive = true;
      }
      setState(() {
        _apiKeys.add(newKey);
      });
      await _prefsService.saveApiKeys(_apiKeys);
    }
  }

  Future<void> _editKey(ApiKey keyToEdit) async {
    final updatedKey = await _showAddOrEditKeyDialog(existingKey: keyToEdit);
    if (updatedKey != null) {
      setState(() {
        final index = _apiKeys.indexWhere((k) => k.id == updatedKey.id);
        if (index != -1) {
          _apiKeys[index] = updatedKey;
        }
      });
      await _prefsService.saveApiKeys(_apiKeys);
    }
  }

  Future<ApiKey?> _showAddOrEditKeyDialog({ApiKey? existingKey}) {
    final isEditing = existingKey != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existingKey?.name ?? '');
    final keyController = TextEditingController(text: existingKey?.key ?? '');

    return showDialog<ApiKey>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Ubah API Key' : 'Tambah API Key Baru'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kunci (e.g., Akun 1)',
                ),
                validator: (val) =>
                    val!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: keyController,
                decoration: const InputDecoration(labelText: 'API Key'),
                validator: (val) =>
                    val!.isEmpty ? 'API Key tidak boleh kosong' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  context,
                  ApiKey(
                    id: existingKey?.id ?? const Uuid().v4(),
                    name: nameController.text.trim(),
                    key: keyController.text.trim(),
                    isActive: existingKey?.isActive ?? false,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeKeyId = _apiKeys
        .firstWhere(
          (k) => k.isActive,
          orElse: () => ApiKey(id: '', name: '', key: ''),
        )
        .id;

    return AlertDialog(
      title: const Text('Manajemen API Key Gemini'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'API Key Tersimpan',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addNewKey,
                    tooltip: 'Tambah Kunci Baru',
                  ),
                ],
              ),
              const Divider(height: 1),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_apiKeys.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      'Belum ada API Key tersimpan.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _apiKeys.length,
                  itemBuilder: (context, index) {
                    final apiKey = _apiKeys[index];
                    return ListTile(
                      title: Text(apiKey.name),
                      subtitle: Text(
                        '...${apiKey.key.substring(apiKey.key.length - 6)}',
                      ),
                      leading: Radio<String>(
                        value: apiKey.id,
                        groupValue: activeKeyId,
                        onChanged: (val) => _setActiveKey(apiKey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _editKey(apiKey),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: () => _deleteKey(apiKey),
                          ),
                        ],
                      ),
                      contentPadding: EdgeInsets.zero,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}
