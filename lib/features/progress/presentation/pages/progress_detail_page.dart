// lib/features/progress/presentation/pages/progress_detail_page.dart

import 'package:flutter/material.dart';
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

  // ... (Fungsi lain tidak berubah) ...
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
  bool _isInitialized = false; // Flag untuk memastikan inisialisasi sekali saja

  // ==> PERBAIKAN: Pindahkan logika dari initState ke didChangeDependencies
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Gunakan flag agar tidak dijalankan berulang kali jika tidak perlu
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
          children: [
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
