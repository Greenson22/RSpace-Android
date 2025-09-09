// lib/features/progress/presentation/widgets/progress_subject_grid_tile.dart

import 'package:flutter/material.dart';
import '../../domain/models/progress_subject_model.dart';

class ProgressSubjectGridTile extends StatelessWidget {
  final ProgressSubject subject;
  final VoidCallback onTap;

  const ProgressSubjectGridTile({
    super.key,
    required this.subject,
    required this.onTap,
  });

  // Helper untuk mendapatkan warna progress
  Color _getProgressColor(String progress) {
    switch (progress) {
      case 'selesai':
        return Colors.green;
      case 'sementara':
        return Colors.orange;
      case 'belum':
      default:
        return Colors.grey.shade300;
    }
  }

  // Helper untuk menghitung nilai progress bar (0.0 to 1.0)
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
    final progressValue = _getProgressValue();
    final progressColor = _getProgressColor(subject.progress);
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
              Text(
                subject.namaMateri,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                '${(progressValue * 100).toStringAsFixed(0)}% Selesai',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: progressColor,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: progressColor.withOpacity(0.2),
                  color: progressColor,
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
