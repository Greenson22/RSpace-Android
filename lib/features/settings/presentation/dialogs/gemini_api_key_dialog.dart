// lib/features/settings/presentation/dialogs/gemini_api_key_dialog.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:my_aplication/features/settings/application/gemini_settings_service.dart';
import 'package:my_aplication/features/settings/domain/models/gemini_settings_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/api_key_model.dart';

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
  final GeminiSettingsService _settingsService = GeminiSettingsService();
  late GeminiSettings _currentSettings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final settings = await _settingsService.loadSettings();
    if (mounted) {
      setState(() {
        _currentSettings = settings;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    await _settingsService.saveSettings(_currentSettings);
  }

  Future<void> _setActiveKey(ApiKey keyToActivate) async {
    final updatedKeys = _currentSettings.apiKeys.map((key) {
      key.isActive = (key.id == keyToActivate.id);
      return key;
    }).toList();

    setState(() {
      _currentSettings = _currentSettings.copyWith(apiKeys: updatedKeys);
    });
    await _saveChanges();
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updatedKeys = _currentSettings.apiKeys
          .where((key) => key.id != keyToDelete.id)
          .toList();

      if (keyToDelete.isActive && updatedKeys.isNotEmpty) {
        if (!updatedKeys.any((k) => k.isActive)) {
          updatedKeys.first.isActive = true;
        }
      }
      setState(() {
        _currentSettings = _currentSettings.copyWith(apiKeys: updatedKeys);
      });
      await _saveChanges();
    }
  }

  Future<void> _addNewKey() async {
    final newKey = await _showAddOrEditKeyDialog();
    if (newKey != null) {
      final updatedKeys = List<ApiKey>.from(_currentSettings.apiKeys);
      if (updatedKeys.isEmpty) {
        newKey.isActive = true;
      }
      updatedKeys.add(newKey);
      setState(() {
        _currentSettings = _currentSettings.copyWith(apiKeys: updatedKeys);
      });
      await _saveChanges();
    }
  }

  Future<void> _editKey(ApiKey keyToEdit) async {
    final updatedKey = await _showAddOrEditKeyDialog(existingKey: keyToEdit);
    if (updatedKey != null) {
      final updatedKeys = List<ApiKey>.from(_currentSettings.apiKeys);
      final index = updatedKeys.indexWhere((k) => k.id == updatedKey.id);
      if (index != -1) {
        updatedKeys[index] = updatedKey;
      }
      setState(() {
        _currentSettings = _currentSettings.copyWith(apiKeys: updatedKeys);
      });
      await _saveChanges();
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
    final activeKeyId = _isLoading
        ? ''
        : _currentSettings.apiKeys
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
              else if (_currentSettings.apiKeys.isEmpty)
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
                  itemCount: _currentSettings.apiKeys.length,
                  itemBuilder: (context, index) {
                    final apiKey = _currentSettings.apiKeys[index];
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
