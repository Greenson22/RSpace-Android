// lib/presentation/pages/dashboard_page/dialogs/gemini_prompt_dialog.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../../data/models/prompt_model.dart';
import '../../../../data/services/shared_preferences_service.dart';

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
  late Prompt _defaultPrompt;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    _defaultPrompt = await _prefsService.getActivePrompt();
    if (_defaultPrompt.isDefault) {
      _defaultPrompt.isActive =
          false; // Non-aktifkan sementara agar bisa dibandingkan
    }

    var savedPrompts = await _prefsService.loadPrompts();
    // Jika tidak ada prompt tersimpan, inisialisasi dengan default
    if (savedPrompts.isEmpty) {
      final defaultPrompt = _prefsService.getActivePrompt() as Prompt;
      defaultPrompt.isActive = true;
      savedPrompts = [defaultPrompt];
    }

    setState(() {
      _prompts = savedPrompts;
      _isLoading = false;
    });
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
        _prompts.first.isActive = true;
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
          if (_prompts.isEmpty) result.isActive = true;
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

  @override
  Widget build(BuildContext context) {
    // Cari prompt yang aktif untuk nilai groupValue di RadioListTile
    final activePromptId = _prompts
        .firstWhere((p) => p.isActive, orElse: () => _defaultPrompt)
        .id;

    return AlertDialog(
      title: const Text('Manajemen Prompt AI'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pilih atau buat prompt yang akan digunakan untuk generate konten. Gunakan placeholder `{topic}` di dalam isi prompt untuk menyisipkan pembahasan.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Divider(height: 24),
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
      ],
    );
  }
}
