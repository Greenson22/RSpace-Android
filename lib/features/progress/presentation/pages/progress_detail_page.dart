// lib/features/progress/presentation/pages/progress_detail_page.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/core/widgets/icon_picker_dialog.dart';
import 'package:provider/provider.dart';
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
                return GridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(constraints.maxWidth),
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: provider.topic.subjects.length,
                  itemBuilder: (context, index) {
                    final subject = provider.topic.subjects[index];
                    return ProgressSubjectGridTile(
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

  // ... (Fungsi _showAddSubjectDialog, _showEditSubjectDialog, _showDeleteConfirmDialog tidak berubah) ...
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

class _ColorPalette {
  final String name;
  final Color background;
  final Color text;
  final Color progressBar;

  _ColorPalette({
    required this.name,
    required this.background,
    required this.text,
    required this.progressBar,
  });
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

  final List<_ColorPalette> _palettes = [
    _ColorPalette(
      name: "Biru Laut",
      background: const Color(0xFF0077B6),
      text: Colors.white,
      progressBar: const Color(0xFFADE8F4),
    ),
    _ColorPalette(
      name: "Gelap Elegan",
      background: const Color(0xFF2B2D42),
      text: Colors.white,
      progressBar: const Color(0xFF8D99AE),
    ),
    _ColorPalette(
      name: "Alam",
      background: const Color(0xFF2d6a4f),
      text: Colors.white,
      progressBar: const Color(0xFF95d5b2),
    ),
    _ColorPalette(
      name: "Matahari Terbenam",
      background: const Color(0xFFf77f00),
      text: Colors.black,
      progressBar: const Color(0xFFfcbf49),
    ),
    _ColorPalette(
      name: "Lavender",
      background: const Color(0xFFe0b1cb),
      text: Colors.black,
      progressBar: const Color(0xFF7251b5),
    ),
    _ColorPalette(
      name: "Terang Minimalis",
      background: const Color(0xFFF8F9FA),
      text: Colors.black,
      progressBar: const Color(0xFF6C757D),
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressDetailProvider>(
      context,
      listen: false,
    );

    return AlertDialog(
      title: const Text('Ubah Tampilan Materi'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==> TAMBAHKAN TOMBOL UBAH IKON DI SINI
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(
                widget.subject.icon,
                style: const TextStyle(fontSize: 24),
              ),
              title: const Text('Ubah Ikon'),
              trailing: const Icon(Icons.edit),
              onTap: () {
                // Panggil dialog ikon yang sudah ada
                showIconPickerDialog(
                  context: context,
                  name: widget.subject.namaMateri,
                  onIconSelected: (newIcon) {
                    provider.updateSubjectIcon(widget.subject, newIcon);
                    // Tutup dialog ubah tampilan setelah memilih ikon
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
            const Divider(height: 24),
            Text(
              'Pilih Palet Cepat',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _palettes.map((palette) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      pickerBackgroundColor = palette.background;
                      pickerTextColor = palette.text;
                      pickerBarColor = palette.progressBar;
                    });
                  },
                  child: Tooltip(
                    message: palette.name,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: palette.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            color: palette.text,
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
            Text(
              'Kustomisasi Manual',
              style: Theme.of(context).textTheme.titleSmall,
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
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
