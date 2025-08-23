// lib/presentation/pages/dashboard_page/dialogs/gemini_api_key_dialog.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/models/api_key_model.dart';
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
  List<ApiKey> _apiKeys = [];
  bool _isLoading = true;
  String? _selectedModelId;

  // Daftar model AI
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
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final keys = await _prefsService.loadApiKeys();
    final modelId = await _prefsService.loadGeminiModel();
    if (mounted) {
      setState(() {
        _apiKeys = keys;
        _selectedModelId = modelId ?? _models.first.id;
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
        // Jika kunci yang aktif dihapus dan masih ada kunci lain,
        // aktifkan kunci pertama sebagai fallback.
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
      // Jika ini adalah kunci pertama yang ditambahkan, otomatis jadikan aktif.
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

  Future<void> _saveModelSelection() async {
    if (_selectedModelId != null) {
      await _prefsService.saveGeminiModel(_selectedModelId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Model AI berhasil disimpan.'),
            backgroundColor: Colors.green,
          ),
        );
      }
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
    return AlertDialog(
      title: const Text('Manajemen Gemini AI'),
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
              DropdownButtonFormField<String>(
                value: _selectedModelId,
                decoration: const InputDecoration(
                  labelText: 'Pilih Model AI',
                  border: OutlineInputBorder(),
                ),
                items: _models.map((model) {
                  return DropdownMenuItem<String>(
                    value: model.id,
                    child: Text(model.name, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedModelId = value;
                  });
                },
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
                      'Belum ada API Key tersimpan.\nTekan tombol + untuk menambah.',
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
                    final activeKeyId = _apiKeys
                        .firstWhere(
                          (k) => k.isActive,
                          orElse: () => ApiKey(id: '', name: '', key: ''),
                        )
                        .id;
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
        ElevatedButton(
          onPressed: _saveModelSelection,
          child: const Text('Simpan Model'),
        ),
      ],
    );
  }
}
