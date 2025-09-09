// lib/features/progress/presentation/pages/progress_detail_page.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/core/widgets/icon_picker_dialog.dart';
import 'package:my_aplication/features/progress/domain/models/color_palette_model.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../../application/progress_detail_provider.dart';
import '../../domain/models/progress_subject_model.dart';
// Import dialog dan widget baru
import '../dialogs/sub_materi_dialog.dart';
import '../widgets/progress_subject_grid_tile.dart';
// Import color picker
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ProgressDetailPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressDetailProvider>(context);

    int _getCrossAxisCount(double screenWidth) {
      if (screenWidth > 1200) return 5;
      if (screenWidth > 900) return 4;
      if (screenWidth > 600) return 3;
      return 2;
    }

    return Scaffold(
      appBar: AppBar(title: Text(provider.topic.topics)),
      body: provider.topic.subjects.isEmpty
          ? const Center(child: Text('Belum ada materi di dalam topik ini.'))
          : LayoutBuilder(
              builder: (context, constraints) {
                return ReorderableGridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(constraints.maxWidth),
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: provider.topic.subjects.length,
                  dragEnabled: false, // Reorder dinonaktifkan sementara
                  onReorder: (oldIndex, newIndex) {
                    // provider.reorderSubjects(oldIndex, newIndex);
                  },
                  itemBuilder: (context, index) {
                    final subject = provider.topic.subjects[index];
                    return ProgressSubjectGridTile(
                      key: ValueKey(subject.namaMateri),
                      subject: subject,
                      onTap: () {
                        showSubMateriDialog(context, subject);
                      },
                      onEdit: () => _showEditSubjectDialog(context, subject),
                      onDelete: () =>
                          _showDeleteConfirmDialog(context, subject),
                      onColorEdit: () =>
                          _showAppearanceDialog(context, subject),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSubjectDialog(context),
        tooltip: 'Tambah Materi Utama',
        child: const Icon(Icons.add_circle_outline),
      ),
    );
  }

  // ... (Fungsi dialog lain tidak berubah) ...
  void _showAddSubjectDialog(BuildContext context) {
    final provider = Provider.of<ProgressDetailProvider>(
      context,
      listen: false,
    );
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Materi Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama Materi'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.addSubject(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Materi baru berhasil ditambahkan.'),
                    backgroundColor: Colors.green,
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

  void _showEditSubjectDialog(BuildContext context, ProgressSubject subject) {
    final provider = Provider.of<ProgressDetailProvider>(
      context,
      listen: false,
    );
    final controller = TextEditingController(text: subject.namaMateri);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah Nama Materi'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama Baru'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.editSubject(subject, controller.text);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, ProgressSubject subject) {
    final provider = Provider.of<ProgressDetailProvider>(
      context,
      listen: false,
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Anda yakin ingin menghapus materi "${subject.namaMateri}" beserta semua sub-materinya?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              provider.deleteSubject(subject);
              Navigator.pop(dialogContext);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showAppearanceDialog(BuildContext context, ProgressSubject subject) {
    final provider = Provider.of<ProgressDetailProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return ChangeNotifierProvider.value(
          value: provider,
          child: _EditAppearanceDialog(subject: subject),
        );
      },
    );
  }
}

class _EditAppearanceDialog extends StatefulWidget {
  final ProgressSubject subject;
  const _EditAppearanceDialog({required this.subject});

  @override
  _EditAppearanceDialogState createState() => _EditAppearanceDialogState();
}

class _EditAppearanceDialogState extends State<_EditAppearanceDialog> {
  late Color pickerBackgroundColor;
  late Color pickerTextColor;
  late Color pickerBarColor;
  bool _isInitialized = false;

  final List<ColorPalette> _defaultPalettes = [
    ColorPalette(
      name: "Biru Laut",
      backgroundColor: 0xFF0077B6,
      textColor: 0xFFFFFFFF,
      progressBarColor: 0xFFADE8F4,
    ),
    ColorPalette(
      name: "Gelap Elegan",
      backgroundColor: 0xFF2B2D42,
      textColor: 0xFFFFFFFF,
      progressBarColor: 0xFF8D99AE,
    ),
    ColorPalette(
      name: "Alam",
      backgroundColor: 0xFF2d6a4f,
      textColor: 0xFFFFFFFF,
      progressBarColor: 0xFF95d5b2,
    ),
    ColorPalette(
      name: "Matahari Terbenam",
      backgroundColor: 0xFFf77f00,
      textColor: 0xFF000000,
      progressBarColor: 0xFFfcbf49,
    ),
    ColorPalette(
      name: "Lavender",
      backgroundColor: 0xFFe0b1cb,
      textColor: 0xFF000000,
      progressBarColor: 0xFF7251b5,
    ),
    ColorPalette(
      name: "Terang Minimalis",
      backgroundColor: 0xFFF8F9FA,
      textColor: 0xFF000000,
      progressBarColor: 0xFF6C757D,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final theme = Theme.of(context);
      pickerBackgroundColor = widget.subject.backgroundColor != null
          ? Color(widget.subject.backgroundColor!)
          : theme.cardColor;
      pickerTextColor = widget.subject.textColor != null
          ? Color(widget.subject.textColor!)
          : (pickerBackgroundColor.computeLuminance() > 0.5
                ? Colors.black87
                : Colors.white);
      pickerBarColor = widget.subject.progressBarColor != null
          ? Color(widget.subject.progressBarColor!)
          : theme.primaryColor;
      _isInitialized = true;
    }
  }

  Widget _buildColorPicker(
    String title,
    Color currentColor,
    ValueChanged<Color> onColorChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            '#${currentColor.value.toRadixString(16).substring(2).toUpperCase()}',
          ),
          trailing: Container(width: 24, height: 24, color: currentColor),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Pilih Warna $title'),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: currentColor,
                    onColorChanged: onColorChanged,
                    enableAlpha: false,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showSavePaletteDialog() {
    final controller = TextEditingController();
    final provider = Provider.of<ProgressDetailProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Simpan Palet Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nama Palet'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final newPalette = ColorPalette(
                  name: controller.text,
                  backgroundColor: pickerBackgroundColor.value,
                  textColor: pickerTextColor.value,
                  progressBarColor: pickerBarColor.value,
                );
                provider.saveNewPalette(newPalette);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // Dialog baru untuk generate palet dengan AI
  void _showAIPaletteDialog() {
    final controller = TextEditingController();
    final provider = Provider.of<ProgressDetailProvider>(
      context,
      listen: false,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isLoading = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Buat Palet dengan AI'),
              content: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsikan tema palet...',
                        hintText: 'Contoh: Hutan tropis, Senja di pantai',
                      ),
                      autofocus: true,
                    ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (controller.text.isNotEmpty) {
                            setDialogState(() => isLoading = true);
                            try {
                              final newPalette = await provider
                                  .generateAndSavePalette(
                                    theme: controller.text,
                                  );
                              // Update color pickers dengan hasil dari AI
                              setState(() {
                                pickerBackgroundColor = Color(
                                  newPalette.backgroundColor,
                                );
                                pickerTextColor = Color(newPalette.textColor);
                                pickerBarColor = Color(
                                  newPalette.progressBarColor,
                                );
                              });
                              Navigator.pop(dialogContext);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setDialogState(() => isLoading = false);
                              }
                            }
                          }
                        },
                  child: const Text('Buat'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProgressDetailProvider>(
      builder: (context, provider, child) {
        final allPalettes = [..._defaultPalettes, ...provider.customPalettes];

        return AlertDialog(
          title: const Text('Ubah Tampilan Materi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(
                    widget.subject.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: const Text('Ubah Ikon'),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    showIconPickerDialog(
                      context: context,
                      name: widget.subject.namaMateri,
                      onIconSelected: (newIcon) {
                        provider.updateSubjectIcon(widget.subject, newIcon);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pilih Palet Cepat',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    // Tombol untuk generate dengan AI
                    TextButton.icon(
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('Buat dg AI'),
                      onPressed: _showAIPaletteDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: allPalettes.map((palette) {
                    final isCustom = provider.customPalettes.contains(palette);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          pickerBackgroundColor = Color(
                            palette.backgroundColor,
                          );
                          pickerTextColor = Color(palette.textColor);
                          pickerBarColor = Color(palette.progressBarColor);
                        });
                      },
                      onLongPress: isCustom
                          ? () {
                              showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Hapus Palet Kustom'),
                                  content: Text(
                                    'Anda yakin ingin menghapus palet "${palette.name}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      onPressed: () {
                                        provider.deleteCustomPalette(palette);
                                        Navigator.pop(dialogContext);
                                      },
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          : null,
                      child: Tooltip(
                        message: palette.name,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(palette.backgroundColor),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Center(
                            child: Text(
                              'A',
                              style: TextStyle(
                                color: Color(palette.textColor),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kustomisasi Manual',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('Simpan Palet'),
                      onPressed: _showSavePaletteDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildColorPicker(
                  'Warna Latar',
                  pickerBackgroundColor,
                  (color) => setState(() => pickerBackgroundColor = color),
                ),
                const SizedBox(height: 16),
                _buildColorPicker(
                  'Warna Teks',
                  pickerTextColor,
                  (color) => setState(() => pickerTextColor = color),
                ),
                const SizedBox(height: 16),
                _buildColorPicker(
                  'Warna Progress Bar',
                  pickerBarColor,
                  (color) => setState(() => pickerBarColor = color),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.updateSubjectColors(
                  widget.subject,
                  backgroundColor: pickerBackgroundColor,
                  textColor: pickerTextColor,
                  progressBarColor: pickerBarColor,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Terapkan & Simpan'),
            ),
          ],
        );
      },
    );
  }
}
