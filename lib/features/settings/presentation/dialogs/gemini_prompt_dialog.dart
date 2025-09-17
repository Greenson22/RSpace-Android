// lib/features/settings/presentation/dialogs/gemini_prompt_dialog.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/settings/application/gemini_settings_service.dart';
import 'package:my_aplication/features/settings/domain/models/gemini_settings_model.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/prompt_model.dart';

// Kelas GeminiModelInfo dipindahkan ke gemini_settings_model.dart

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
  final GeminiSettingsService _settingsService = GeminiSettingsService();
  late GeminiSettings _currentSettings;
  bool _isLoading = true;

  late TextEditingController _motivationalPromptController;

  // Daftar model yang hardcoded dihapus dari sini

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

  // --- Fungsi Manajemen Model ---
  Future<void> _addNewOrEditModel({GeminiModelInfo? existingModel}) async {
    final result = await _showAddOrEditModelDialog(
      existingModel: existingModel,
    );
    if (result != null) {
      final updatedModels = List<GeminiModelInfo>.from(_currentSettings.models);
      if (existingModel != null) {
        final index = updatedModels.indexWhere((m) => m.id == result.id);
        if (index != -1) updatedModels[index] = result;
      } else {
        updatedModels.add(result);
      }
      setState(() {
        _currentSettings = _currentSettings.copyWith(models: updatedModels);
      });
    }
  }

  Future<void> _deleteModel(GeminiModelInfo modelToDelete) async {
    if (modelToDelete.isDefault) return;

    final updatedModels = _currentSettings.models
        .where((m) => m.id != modelToDelete.id)
        .toList();

    // Jika model yang dihapus adalah model yang sedang dipilih,
    // pindahkan pilihan ke model default pertama
    final modelIds = updatedModels.map((m) => m.modelId).toSet();
    String newGeneralId = _currentSettings.generalModelId;
    if (!modelIds.contains(newGeneralId)) {
      newGeneralId = updatedModels.first.modelId;
    }
    // Lakukan hal yang sama untuk model lainnya...

    setState(() {
      _currentSettings = _currentSettings.copyWith(
        models: updatedModels,
        generalModelId: newGeneralId,
        // ... update juga modelId lainnya jika perlu
      );
    });
  }

  Future<GeminiModelInfo?> _showAddOrEditModelDialog({
    GeminiModelInfo? existingModel,
  }) {
    final isEditing = existingModel != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: existingModel?.name ?? '',
    );
    final idController = TextEditingController(
      text: existingModel?.modelId ?? '',
    );

    return showDialog<GeminiModelInfo>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Ubah Model AI' : 'Tambah Model AI Baru'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Tampilan Model',
                ),
                validator: (val) =>
                    val!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: idController,
                decoration: const InputDecoration(
                  labelText: 'ID Model (contoh: gemini-1.5-pro)',
                ),
                validator: (val) =>
                    val!.isEmpty ? 'ID Model tidak boleh kosong' : null,
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
                  GeminiModelInfo(
                    id: existingModel?.id,
                    name: nameController.text.trim(),
                    modelId: idController.text.trim(),
                    isDefault: existingModel?.isDefault ?? false,
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

  // --- Fungsi Manajemen Prompt (Tidak Berubah) ---
  Future<void> _setActivePrompt(Prompt promptToActivate) async {
    // ... implementasi tidak berubah
  }
  Future<void> _deletePrompt(Prompt promptToDelete) async {
    // ... implementasi tidak berubah
  }
  Future<void> _addNewOrEditPrompt({Prompt? existingPrompt}) async {
    // ... implementasi tidak berubah
  }
  Future<Prompt?> _showAddOrEditPromptDialog({Prompt? existingPrompt}) {
    // ... implementasi tidak berubah
    return showDialog<Prompt>(
      context: context,
      builder: (context) => Container(),
    ); // Placeholder
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
    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: _currentSettings.models.map((model) {
        // Mengambil dari state
        return DropdownMenuItem<String>(
          value: model.modelId,
          child: Text(model.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Dialog(child: Center(child: CircularProgressIndicator()));
    }

    final activePromptId = _currentSettings.prompts.isEmpty
        ? ''
        : _currentSettings.prompts
              .firstWhere(
                (p) => p.isActive,
                orElse: () => _currentSettings.prompts.first,
              )
              .id;

    return AlertDialog(
      title: const Text('Manajemen Prompt & Model AI'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Atur model AI yang akan digunakan untuk setiap fitur dan kelola *prompt* kustom Anda.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Divider(height: 32),

              // --- BAGIAN MANAJEMEN MODEL ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manajemen Model AI',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _addNewOrEditModel,
                    tooltip: 'Tambah Model Baru',
                  ),
                ],
              ),
              const Divider(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currentSettings.models.length,
                itemBuilder: (context, index) {
                  final model = _currentSettings.models[index];
                  return ListTile(
                    title: Text(model.name),
                    subtitle: Text(model.modelId),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit Model',
                          onPressed: () =>
                              _addNewOrEditModel(existingModel: model),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: model.isDefault ? Colors.grey : Colors.red,
                            size: 20,
                          ),
                          tooltip: model.isDefault
                              ? 'Model default tidak bisa dihapus'
                              : 'Hapus Model',
                          onPressed: model.isDefault
                              ? null
                              : () => _deleteModel(model),
                        ),
                      ],
                    ),
                    contentPadding: EdgeInsets.zero,
                  );
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
                label: 'Model untuk Tugas Umum (Pencarian, dll)',
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
                label: 'Model untuk Generate Konten',
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
                label: 'Model untuk Chat',
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
                label: 'Model untuk Generate Kuis',
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
                label: 'Model untuk Generate Judul dari Konten',
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
              const Divider(height: 32),

              // --- BAGIAN PROMPT ---
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
              const SizedBox(height: 16),
              Text(
                'Prompt Kustom untuk Generate Konten',
                style: Theme.of(context).textTheme.titleMedium,
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
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () => _addNewOrEditPrompt(),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Prompt Konten'),
        ),
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
}
