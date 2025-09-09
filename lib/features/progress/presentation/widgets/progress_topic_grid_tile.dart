// lib/features/progress/presentation/widgets/progress_topic_grid_tile.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/progress/domain/models/progress_topic_model.dart';

class ProgressTopicGridTile extends StatelessWidget {
  final ProgressTopic topic;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onIconChange;

  const ProgressTopicGridTile({
    super.key,
    required this.topic,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onIconChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Konten utama yang akan berada di tengah
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment:
                    CrossAxisAlignment.stretch, // Agar teks center
                children: [
                  Text(
                    topic.icon,
                    style: TextStyle(
                      fontSize: 40, // Perbesar ukuran ikon
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    topic.topics,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Tombol menu di pojok kanan atas
            Positioned(
              top: 4,
              right: 4,
              child: SizedBox(
                width: 24,
                height: 24,
                child: PopupMenuButton<String>(
                  iconSize: 18,
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    } else if (value == 'icon') {
                      onIconChange();
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Edit Nama'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'icon',
                          child: Text('Ubah Ikon'),
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
            ),
          ],
        ),
      ),
    );
  }
}
