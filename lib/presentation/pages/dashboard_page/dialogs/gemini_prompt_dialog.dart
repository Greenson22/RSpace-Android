// lib/presentation/pages/dashboard_page/dialogs/gemini_prompt_dialog.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/models/api_key_model.dart';
import '../../../../data/models/prompt_model.dart';
import '../../../../data/services/shared_preferences_service.dart';

// Kelas helper untuk data model
class GeminiModelInfo {
  final String name;
  final String id;
  const GeminiModelInfo({required this.name, required this.id});
}

void showGeminiPromptDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const GeminiPromptDialog(),
  );
}

class GeminiPromptDialog extends StatefulWidget {
  const GeminiPromptDialog({super.key});

  @override
  State<GeminiPromptDialog> createState() => _GeminiPromptDialogState();
}

class _GeminiPromptDialogState extends State<GeminiPromptDialog> {
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  List<Prompt> _prompts = [];
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
    var savedPrompts = await _prefsService.loadPrompts();
    final modelId = await _prefsService.loadGeminiModel();

    // Jika tidak ada prompt tersimpan (kasus pertama kali buka),
    // inisialisasi dengan prompt default.
    if (savedPrompts.isEmpty) {
      final defaultPrompt = await _prefsService.getActivePrompt();
      savedPrompts = [defaultPrompt];
      await _prefsService.savePrompts(savedPrompts);
    }

    // Pastikan selalu ada satu prompt yang aktif.
    if (!savedPrompts.any((p) => p.isActive)) {
      final defaultOrFirst = savedPrompts.firstWhere(
        (p) => p.isDefault,
        orElse: () => savedPrompts.first,
      );
      defaultOrFirst.isActive = true;
    }

    if (mounted) {
      setState(() {
        _prompts = savedPrompts;
        _selectedModelId = modelId ?? _models.first.id;
        _isLoading = false;
      });
    }
  }

  Future<void> _setActivePrompt(Prompt promptToActivate) async {
    setState(() {
      for (var p in _prompts) {
        p.isActive = (p.id == promptToActivate.id);
      }
    });
    await _prefsService.savePrompts(_prompts);
  }

  Future<void> _deletePrompt(Prompt promptToDelete) async {
    if (promptToDelete.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prompt default tidak dapat dihapus.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _prompts.removeWhere((p) => p.id == promptToDelete.id);
      if (promptToDelete.isActive && _prompts.isNotEmpty) {
        _prompts
                .firstWhere((p) => p.isDefault, orElse: () => _prompts.first)
                .isActive =
            true;
      }
    });
    await _prefsService.savePrompts(_prompts);
  }

  Future<void> _addNewOrEditPrompt({Prompt? existingPrompt}) async {
    final result = await _showAddOrEditPromptDialog(
      existingPrompt: existingPrompt,
    );
    if (result != null) {
      setState(() {
        if (existingPrompt != null) {
          final index = _prompts.indexWhere((p) => p.id == result.id);
          if (index != -1) _prompts[index] = result;
        } else {
          _prompts.add(result);
        }
      });
      await _prefsService.savePrompts(_prompts);
    }
  }

  Future<Prompt?> _showAddOrEditPromptDialog({Prompt? existingPrompt}) {
    final isEditing = existingPrompt != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: existingPrompt?.name ?? '',
    );
    final contentController = TextEditingController(
      text: existingPrompt?.content ?? '',
    );

    return showDialog<Prompt>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Ubah Prompt' : 'Tambah Prompt Baru'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Prompt'),
                  validator: (val) =>
                      val!.isEmpty ? 'Nama tidak boleh kosong' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Isi Prompt',
                    hintText: 'Gunakan "{topic}" sebagai placeholder...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 10,
                  validator: (val) =>
                      val!.isEmpty ? 'Isi tidak boleh kosong' : null,
                ),
              ],
            ),
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
                  Prompt(
                    id: existingPrompt?.id ?? const Uuid().v4(),
                    name: nameController.text.trim(),
                    content: contentController.text.trim(),
                    isActive: existingPrompt?.isActive ?? false,
                    isDefault: existingPrompt?.isDefault ?? false,
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

  @override
  Widget build(BuildContext context) {
    final activePromptId = _isLoading || _prompts.isEmpty
        ? ''
        : _prompts
              .firstWhere((p) => p.isActive, orElse: () => _prompts.first)
              .id;

    return AlertDialog(
      title: const Text('Manajemen Prompt AI'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pilih atau buat prompt yang akan digunakan untuk generate konten. Gunakan placeholder `{topic}` di dalam isi prompt untuk menyisipkan pembahasan.',
                      style: Theme.of(context).textTheme.bodySmall,
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
                          child: Text(
                            model.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedModelId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Prompt Tersimpan',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Divider(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _prompts.length,
                      itemBuilder: (context, index) {
                        final prompt = _prompts[index];
                        return ListTile(
                          title: Text(prompt.name),
                          subtitle: prompt.isDefault
                              ? const Text('Prompt Standar')
                              : null,
                          leading: Radio<String>(
                            value: prompt.id,
                            groupValue: activePromptId,
                            onChanged: (val) => _setActivePrompt(prompt),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () =>
                                    _addNewOrEditPrompt(existingPrompt: prompt),
                              ),
                              if (!prompt.isDefault)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () => _deletePrompt(prompt),
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
        OutlinedButton.icon(
          onPressed: () => _addNewOrEditPrompt(),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Baru'),
        ),
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
