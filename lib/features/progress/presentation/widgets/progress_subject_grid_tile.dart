// lib/features/progress/presentation/widgets/progress_subject_grid_tile.dart

import 'package:flutter/material.dart';
import '../../domain/models/progress_subject_model.dart';

class ProgressSubjectGridTile extends StatelessWidget {
  final ProgressSubject subject;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onColorEdit; // Callback baru untuk warna

  const ProgressSubjectGridTile({
    super.key,
    required this.subject,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onColorEdit, // Tambahkan di konstruktor
  });

  Color _getProgressColor(String progress, Color defaultColor) {
    if (progress == 'selesai') return Colors.green;
    if (progress == 'sementara') return Colors.orange;
    return defaultColor.withOpacity(0.3); // Gunakan warna default jika 'belum'
  }

  double _getProgressValue() {
    if (subject.subMateri.isEmpty) {
      switch (subject.progress) {
        case 'selesai':
          return 1.0;
        case 'sementara':
          return 0.5;
        default:
          return 0.0;
      }
    }
    final finishedCount = subject.subMateri
        .where((s) => s.progress == 'selesai')
        .length;
    return finishedCount / subject.subMateri.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Gunakan warna dari subject, atau warna primer tema sebagai default
    final subjectColor = subject.color != null
        ? Color(subject.color!)
        : theme.primaryColor;
    final progressValue = _getProgressValue();
    final progressColor = _getProgressColor(subject.progress, subjectColor);
    final totalSubMateri = subject.subMateri.length;
    final selesaiCount = subject.subMateri
        .where((s) => s.progress == 'selesai')
        .length;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      subject.namaMateri,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: PopupMenuButton<String>(
                      iconSize: 18,
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit();
                        } else if (value == 'delete') {
                          onDelete();
                        } else if (value == 'color') {
                          // Aksi baru
                          onColorEdit();
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Edit Nama'),
                            ),
                            // Tambahkan item menu baru
                            const PopupMenuItem<String>(
                              value: 'color',
                              child: Text('Ubah Warna'),
                            ),
                            const PopupMenuDivider(),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: Text(
                                'Hapus',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${(progressValue * 100).toStringAsFixed(0)}% Selesai',
                style: theme.textTheme.bodySmall?.copyWith(color: subjectColor),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: subjectColor.withOpacity(0.2),
                  color: subjectColor, // Selalu gunakan warna subject
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$selesaiCount dari $totalSubMateri sub-materi',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
