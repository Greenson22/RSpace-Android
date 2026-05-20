// lib/features/progress/presentation/pages/progress_detail_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import 'package:my_aplication/core/widgets/icon_picker_dialog.dart';
import 'package:my_aplication/features/progress/domain/models/color_palette_model.dart';
import '../../application/progress_detail_provider.dart';
import '../../domain/models/progress_subject_model.dart';
import '../dialogs/sub_materi_dialog.dart';
import '../widgets/progress_subject_grid_tile.dart';
import '../../../settings/application/theme_provider.dart';

class ProgressDetailPage extends StatefulWidget {
  const ProgressDetailPage({super.key});

  @override
  State<ProgressDetailPage> createState() => _ProgressDetailPageState();
}

class _ProgressDetailPageState extends State<ProgressDetailPage> {
  bool _isReorderMode = false;

  // State untuk Multi-select
  bool _isSelectionMode = false;
  final Set<ProgressSubject> _selectedSubjects = {};

  void _enterSelectionMode(ProgressSubject? initialSubject) {
    setState(() {
      _isSelectionMode = true;
      _isReorderMode = false; // Matikan reorder jika aktif
      if (initialSubject != null) {
        _selectedSubjects.add(initialSubject);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedSubjects.clear();
    });
  }

  void _toggleItemSelection(ProgressSubject subject) {
    setState(() {
      if (_selectedSubjects.contains(subject)) {
        _selectedSubjects.remove(subject);
        if (_selectedSubjects.isEmpty) {
          _exitSelectionMode();
        }
      } else {
        _selectedSubjects.add(subject);
      }
    });
  }

  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth > 1200) return 5;
    if (screenWidth > 900) return 4;
    if (screenWidth > 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressDetailProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isTransparent =
        themeProvider.backgroundImagePath != null ||
        themeProvider.isUnderwaterTheme;

    return Scaffold(
      backgroundColor: isTransparent ? Colors.transparent : null,
      appBar: _isSelectionMode
          ? _buildSelectionAppBar(context, provider, isTransparent)
          : _buildNormalAppBar(context, provider, isTransparent),
      body: provider.topic.subjects.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Belum ada materi di dalam topik ini.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = _getCrossAxisCount(constraints.maxWidth);

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(
                    bottom: 80.0,
                  ), // Ruang untuk FAB
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionGrid(
                        context: context,
                        title: '⭐ Fokus Utama',
                        sectionId: 'focus',
                        subjects: provider.focusSubjects,
                        crossAxisCount: crossAxisCount,
                        provider: provider,
                      ),
                      _buildSectionGrid(
                        context: context,
                        title: '📥 Antrean Materi',
                        sectionId: 'queue',
                        subjects: provider.queueSubjects,
                        crossAxisCount: crossAxisCount,
                        provider: provider,
                      ),
                      _buildSectionGrid(
                        context: context,
                        title: '☕ Materi Tambahan',
                        sectionId: 'additional',
                        subjects: provider.additionalSubjects,
                        crossAxisCount: crossAxisCount,
                        provider: provider,
                      ),
                      _buildSectionGrid(
                        context: context,
                        title: '📦 Arsip',
                        sectionId: 'archive',
                        subjects: provider.archiveSubjects,
                        crossAxisCount: crossAxisCount,
                        provider: provider,
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: (_isReorderMode || _isSelectionMode)
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddSubjectDialog(context),
              tooltip: 'Tambah Materi Utama',
              child: const Icon(Icons.add_circle_outline),
            ),
    );
  }

  // --- Widget Builder per Bagian (Section) ---
  Widget _buildSectionGrid({
    required BuildContext context,
    required String title,
    required String sectionId,
    required List<ProgressSubject> subjects,
    required int crossAxisCount,
    required ProgressDetailProvider provider,
  }) {
    // Sembunyikan section kosong jika bukan mode reorder/selection
    if (subjects.isEmpty && !_isReorderMode && !_isSelectionMode) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        if (subjects.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Kosong',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          )
        else
          // Menggunakan ReorderableGridView.builder untuk masing-masing bagian
          ReorderableGridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 1.2,
            ),
            itemCount: subjects.length,
            dragEnabled: _isReorderMode && !_isSelectionMode,
            onReorder: (oldIndex, newIndex) {
              provider.reorderSubjectInSection(sectionId, oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return ProgressSubjectGridTile(
                key: ValueKey(subject.namaMateri), // Key wajib untuk reorder
                subject: subject,
                isSelectionMode: _isSelectionMode,
                isSelected: _selectedSubjects.contains(subject),
                onSelect: () => _toggleItemSelection(subject),
                onLongPress: _isReorderMode
                    ? null
                    : () => _enterSelectionMode(subject),
                onTap: () {
                  if (!_isReorderMode && !_isSelectionMode) {
                    showSubMateriDialog(context, subject);
                  }
                },
                onEdit: () => _showEditSubjectDialog(context, subject),
                onDelete: () => _showDeleteConfirmDialog(context, subject),
                onColorEdit: () => _showAppearanceDialog(context, subject),
                onHide: () => provider.toggleSubjectVisibility(subject),
              );
            },
          ),
      ],
    );
  }

  // --- AppBar Builders ---

  PreferredSizeWidget _buildNormalAppBar(
    BuildContext context,
    ProgressDetailProvider provider,
    bool isTransparent,
  ) {
    return AppBar(
      backgroundColor: isTransparent ? Colors.transparent : null,
      elevation: isTransparent ? 0 : null,
      title: Text(provider.topic.topics),
      actions: [
        IconButton(
          icon: Icon(
            provider.showHidden ? Icons.visibility : Icons.visibility_off,
          ),
          tooltip: provider.showHidden
              ? 'Sembunyikan Materi Hidden'
              : 'Tampilkan Materi Hidden',
          onPressed: () {
            provider.toggleShowHidden();
          },
        ),
        IconButton(
          icon: Icon(_isReorderMode ? Icons.check : Icons.sort),
          onPressed: () {
            setState(() {
              _isReorderMode = !_isReorderMode;
            });
          },
          tooltip: _isReorderMode ? 'Selesai Mengurutkan' : 'Urutkan Materi',
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'select_multiple') {
              if (provider.topic.subjects.isNotEmpty) {
                _enterSelectionMode(null);
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'select_multiple',
              child: ListTile(
                leading: Icon(Icons.checklist),
                title: Text('Pilih Banyak'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSelectionAppBar(
    BuildContext context,
    ProgressDetailProvider provider,
    bool isTransparent,
  ) {
    return AppBar(
      backgroundColor: isTransparent ? Colors.transparent : Colors.grey[800],
      elevation: isTransparent ? 0 : null,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitSelectionMode,
      ),
      title: Text('${_selectedSubjects.length} Dipilih'),
      actions: [
        if (_selectedSubjects.isNotEmpty) ...[
          IconButton(
            icon: const Icon(Icons.drive_file_move_outline),
            tooltip: 'Pindahkan Bagian',
            onPressed: () => _handleBatchMoveSection(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'Ubah Visibilitas',
            onPressed: () => _handleBatchVisibility(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Hapus Terpilih',
            onPressed: () => _handleBatchDelete(context, provider),
          ),
        ],
      ],
    );
  }

  // --- Dialog Logics ---

  void _handleBatchMoveSection(
    BuildContext context,
    ProgressDetailProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Pindahkan ${_selectedSubjects.length} Materi Ke...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.star, color: Colors.orange),
              title: const Text('Fokus Utama'),
              onTap: () {
                provider.moveMultipleSubjectsToSection(
                  _selectedSubjects.toList(),
                  'focus',
                );
                _exitSelectionMode();
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inbox, color: Colors.blue),
              title: const Text('Antrean Materi'),
              onTap: () {
                provider.moveMultipleSubjectsToSection(
                  _selectedSubjects.toList(),
                  'queue',
                );
                _exitSelectionMode();
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.low_priority, color: Colors.grey),
              title: const Text('Materi Tambahan'),
              onTap: () {
                provider.moveMultipleSubjectsToSection(
                  _selectedSubjects.toList(),
                  'additional',
                );
                _exitSelectionMode();
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2, color: Colors.brown),
              title: const Text('Arsip'),
              onTap: () {
                provider.moveMultipleSubjectsToSection(
                  _selectedSubjects.toList(),
                  'archive',
                );
                _exitSelectionMode();
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleBatchVisibility(
    BuildContext context,
    ProgressDetailProvider provider,
  ) {
    final anyVisible = _selectedSubjects.any((s) => !s.isHidden);
    final actionLabel = anyVisible ? 'Sembunyikan' : 'Tampilkan';
    final makeHidden = anyVisible;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$actionLabel ${_selectedSubjects.length} Materi?'),
        content: const Text(
          'Aksi ini akan mengubah status visibilitas materi yang dipilih.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              provider.toggleVisibilityMultipleSubjects(
                _selectedSubjects.toList(),
                makeHidden,
              );
              _exitSelectionMode();
              Navigator.pop(context);
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  void _handleBatchDelete(
    BuildContext context,
    ProgressDetailProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus ${_selectedSubjects.length} Materi?'),
        content: const Text(
          'Materi yang dihapus beserta semua sub-materinya tidak dapat dikembalikan. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              provider.deleteMultipleSubjects(_selectedSubjects.toList());
              _exitSelectionMode();
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

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
                // Secara default materi baru akan masuk ke Antrean Materi (queue)
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

// --- Kelas Dialog Appearance (Tetap Sama) ---

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

  void _showAIPaletteDialog() {
    final controller = TextEditingController(text: widget.subject.namaMateri);
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
