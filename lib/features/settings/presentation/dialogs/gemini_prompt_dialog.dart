// lib/features/settings/presentation/dialogs/gemini_prompt_dialog.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/settings/application/gemini_settings_service.dart';
import 'package:my_aplication/features/settings/domain/models/gemini_settings_model.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/prompt_model.dart';
// Import dialog baru
import 'gemini_model_management_dialog.dart';

void showGeminiPromptDialog(BuildContext context) {
  showDialog(
    context: context,
    useSafeArea: false,
    builder: (context) => const GeminiPromptDialog(),
  );
}

class GeminiPromptDialog extends StatefulWidget {
  const GeminiPromptDialog({super.key});

  @override
  State<GeminiPromptDialog> createState() => _GeminiPromptDialogState();
}

class _GeminiPromptDialogState extends State<GeminiPromptDialog> {
  final GeminiSettingsService _settingsService = GeminiSettingsService();
  late GeminiSettings _currentSettings;
  bool _isLoading = true;

  late TextEditingController _motivationalPromptController;

  @override
  void initState() {
    super.initState();
    _motivationalPromptController = TextEditingController();
    _loadSavedData();
  }

  @override
  void dispose() {
    _motivationalPromptController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final settings = await _settingsService.loadSettings();

    if (settings.prompts.isNotEmpty &&
        !settings.prompts.any((p) => p.isActive)) {
      final defaultOrFirst = settings.prompts.firstWhere(
        (p) => p.isDefault,
        orElse: () => settings.prompts.first,
      );
      defaultOrFirst.isActive = true;
    }

    if (mounted) {
      setState(() {
        _currentSettings = settings;
        _motivationalPromptController.text =
            _currentSettings.motivationalQuotePrompt;
        _isLoading = false;
      });
    }
  }

  // --- Fungsi Manajemen Prompt (Tidak Berubah) ---
  Future<void> _setActivePrompt(Prompt promptToActivate) async {
    final updatedPrompts = _currentSettings.prompts.map((p) {
      p.isActive = (p.id == promptToActivate.id);
      return p;
    }).toList();

    setState(() {
      _currentSettings = _currentSettings.copyWith(prompts: updatedPrompts);
    });
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

    final updatedPrompts = _currentSettings.prompts
        .where((p) => p.id != promptToDelete.id)
        .toList();

    if (promptToDelete.isActive && updatedPrompts.isNotEmpty) {
      if (!updatedPrompts.any((k) => k.isActive)) {
        updatedPrompts.first.isActive = true;
      }
    }

    setState(() {
      _currentSettings = _currentSettings.copyWith(prompts: updatedPrompts);
    });
  }

  Future<void> _addNewOrEditPrompt({Prompt? existingPrompt}) async {
    final result = await _showAddOrEditPromptDialog(
      existingPrompt: existingPrompt,
    );
    if (result != null) {
      final updatedPrompts = List<Prompt>.from(_currentSettings.prompts);
      if (existingPrompt != null) {
        final index = updatedPrompts.indexWhere((p) => p.id == result.id);
        if (index != -1) updatedPrompts[index] = result;
      } else {
        updatedPrompts.add(result);
      }
      setState(() {
        _currentSettings = _currentSettings.copyWith(prompts: updatedPrompts);
      });
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

  Future<void> _saveAllSettings() async {
    final settingsToSave = _currentSettings.copyWith(
      motivationalQuotePrompt: _motivationalPromptController.text.trim(),
    );
    await _settingsService.saveSettings(settingsToSave);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengaturan model & prompt AI berhasil disimpan.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  Widget _buildModelDropdown({
    required String label,
    required String? currentValue,
    required ValueChanged<String?> onChanged,
  }) {
    final uniqueModels = <String>{};
    final items = _currentSettings.models
        .where((model) => uniqueModels.add(model.modelId))
        .map((model) {
          return DropdownMenuItem<String>(
            value: model.modelId,
            child: Text(model.name, overflow: TextOverflow.ellipsis),
          );
        })
        .toList();

    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      isExpanded: true,
      items: items,
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(child: Center(child: CircularProgressIndicator()));
    }

    return AlertDialog(
      title: const Text('Manajemen Prompt & Model AI'),
      content: DefaultTabController(
        length: 2,
        child: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'Pengaturan Model'),
                  Tab(text: 'Pengaturan Prompt'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildModelSettingsTab(),
                    _buildPromptSettingsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _saveAllSettings,
          child: const Text('Simpan & Tutup'),
        ),
      ],
    );
  }

  Widget _buildModelSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Tombol untuk membuka dialog manajemen model ---
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Kelola Daftar Model AI'),
            subtitle: const Text('Tambah, ubah, atau hapus model kustom.'),
            onTap: () async {
              final updatedModels = await showGeminiModelManagementDialog(
                context,
                currentModels: _currentSettings.models,
              );
              if (updatedModels != null) {
                // Perbarui state dengan daftar model baru dari dialog
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    models: updatedModels,
                  );
                });
              }
            },
          ),
          const Divider(height: 32),

          // --- BAGIAN PEMILIHAN MODEL ---
          Text(
            'Pemilihan Model per Fitur',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _buildModelDropdown(
            label: 'Tugas Umum (Pencarian, dll)',
            currentValue: _currentSettings.generalModelId,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    generalModelId: value,
                  );
                });
              }
            },
          ),
          const SizedBox(height: 16),
          _buildModelDropdown(
            label: 'Generate Konten',
            currentValue: _currentSettings.contentModelId,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    contentModelId: value,
                  );
                });
              }
            },
          ),
          const SizedBox(height: 16),
          _buildModelDropdown(
            label: 'Chat',
            currentValue: _currentSettings.chatModelId,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    chatModelId: value,
                  );
                });
              }
            },
          ),
          const SizedBox(height: 16),
          _buildModelDropdown(
            label: 'Generate Kuis',
            currentValue: _currentSettings.quizModelId,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    quizModelId: value,
                  );
                });
              }
            },
          ),
          const SizedBox(height: 16),
          _buildModelDropdown(
            label: 'Generate Judul',
            currentValue: _currentSettings.titleGenerationModelId,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _currentSettings = _currentSettings.copyWith(
                    titleGenerationModelId: value,
                  );
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPromptSettingsTab() {
    final activePromptId = _currentSettings.prompts.isEmpty
        ? ''
        : _currentSettings.prompts
              .firstWhere(
                (p) => p.isActive,
                orElse: () => _currentSettings.prompts.first,
              )
              .id;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prompt untuk Kata Motivasi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _motivationalPromptController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Masukkan perintah untuk AI...',
            ),
            maxLines: 4,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              child: const Text('Gunakan Default'),
              onPressed: () {
                setState(() {
                  _motivationalPromptController.text =
                      defaultMotivationalPrompt;
                });
              },
            ),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prompt Kustom (Generate Konten)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _addNewOrEditPrompt(),
                tooltip: 'Tambah Prompt Baru',
              ),
            ],
          ),
          const Divider(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _currentSettings.prompts.length,
            itemBuilder: (context, index) {
              final prompt = _currentSettings.prompts[index];
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
    );
  }
}
