// lib/features/progress/presentation/widgets/progress_subject_grid_tile.dart

import 'package:flutter/material.dart';
import '../../domain/models/progress_subject_model.dart';

class ProgressSubjectGridTile extends StatelessWidget {
  final ProgressSubject subject;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onColorEdit;

  const ProgressSubjectGridTile({
    super.key,
    required this.subject,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onColorEdit,
  });

  Color _getAdaptiveTextColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.5
        ? Colors.black87
        : Colors.white;
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

    final backgroundColor = subject.backgroundColor != null
        ? Color(subject.backgroundColor!)
        : theme.cardColor;

    final textColor = subject.textColor != null
        ? Color(subject.textColor!)
        : _getAdaptiveTextColor(backgroundColor);

    final progressBarColor = subject.progressBarColor != null
        ? Color(subject.progressBarColor!)
        : theme.primaryColor;

    final progressValue = _getProgressValue();
    final totalSubMateri = subject.subMateri.length;
    final selesaiCount = subject.subMateri
        .where((s) => s.progress == 'selesai')
        .length;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      color: backgroundColor,
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
                  // Tampilkan ikon di sini
                  Text(
                    subject.icon,
                    style: TextStyle(fontSize: 24, color: textColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subject.namaMateri,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
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
                      icon: Icon(Icons.more_vert, color: textColor),
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit();
                        } else if (value == 'delete') {
                          onDelete();
                        } else if (value == 'color') {
                          onColorEdit();
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Edit Nama'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'color',
                              child: Text('Ubah Tampilan'),
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
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: progressBarColor.withOpacity(0.2),
                  color: progressBarColor,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$selesaiCount dari $totalSubMateri sub-materi',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
