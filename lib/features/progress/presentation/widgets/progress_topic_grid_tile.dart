// lib/features/progress/presentation/widgets/progress_topic_grid_tile.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/progress/domain/models/progress_topic_model.dart';

class ProgressTopicGridTile extends StatelessWidget {
  final ProgressTopic topic;
  final VoidCallback onTap;
  // Tambahkan callback baru
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProgressTopicGridTile({
    super.key,
    required this.topic,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              // Gunakan Row untuk menempatkan menu di kanan
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 32,
                    color: theme.primaryColor,
                  ),
                  const Spacer(),
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
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: Text('Edit Nama'),
                            ),
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
                topic.topics,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
