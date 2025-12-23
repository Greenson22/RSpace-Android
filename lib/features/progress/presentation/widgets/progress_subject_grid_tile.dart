// lib/features/progress/presentation/widgets/progress_subject_grid_tile.dart

import 'package:flutter/material.dart';
import '../../domain/models/progress_subject_model.dart';

class ProgressSubjectGridTile extends StatelessWidget {
  final ProgressSubject subject;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onColorEdit;
  // ==> TAMBAHAN PARAMETER BARU <==
  final VoidCallback? onLongPress;
  final VoidCallback? onHide;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelect;

  const ProgressSubjectGridTile({
    super.key,
    required this.subject,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onColorEdit,
    this.onLongPress,
    this.onHide,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelect,
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

    // Jika item hidden dan tidak dalam selection mode, beri efek visual
    Color backgroundColor = subject.backgroundColor != null
        ? Color(subject.backgroundColor!)
        : theme.cardColor;

    if (subject.isHidden) {
      backgroundColor = backgroundColor.withOpacity(0.6);
    }

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        // Beri border jika item dipilih
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 3.0)
            : BorderSide.none,
      ),
      color: backgroundColor,
      child: InkWell(
        onTap: isSelectionMode ? onSelect : onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            // Coret teks jika hidden
                            decoration: subject.isHidden
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Popup Menu hanya muncul jika TIDAK selection mode
                      if (!isSelectionMode)
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
                              } else if (value == 'hide') {
                                if (onHide != null) onHide!();
                              }
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: Icon(Icons.edit_outlined),
                                      title: Text('Edit Nama'),
                                    ),
                                  ),
                                  const PopupMenuItem<String>(
                                    value: 'color',
                                    child: ListTile(
                                      leading: Icon(Icons.palette_outlined),
                                      title: Text('Ubah Tampilan'),
                                    ),
                                  ),
                                  // Menu Hide/Show
                                  PopupMenuItem<String>(
                                    value: 'hide',
                                    child: ListTile(
                                      leading: Icon(
                                        subject.isHidden
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      title: Text(
                                        subject.isHidden
                                            ? 'Tampilkan'
                                            : 'Sembunyikan',
                                      ),
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      title: Text(
                                        'Hapus',
                                        style: TextStyle(color: Colors.red),
                                      ),
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

              // Checkbox untuk selection mode
              if (isSelectionMode)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? theme.primaryColor : Colors.white,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? null
                          : Border.all(color: Colors.grey),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.transparent,
                    ),
                  ),
                ),

              // Indikator visual hidden (mata disilang)
              if (subject.isHidden && !isSelectionMode)
                Positioned(
                  bottom: 40,
                  right: 0,
                  child: Icon(
                    Icons.visibility_off,
                    size: 16,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
