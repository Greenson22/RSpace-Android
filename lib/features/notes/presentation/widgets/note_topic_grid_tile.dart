// lib/features/notes/presentation/widgets/note_topic_grid_tile.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/notes/domain/models/note_topic_model.dart';

class NoteTopicGridTile extends StatelessWidget {
  final NoteTopic topic;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onIconChange;
  final VoidCallback onDelete;

  const NoteTopicGridTile({
    super.key,
    required this.topic,
    required this.onTap,
    required this.onRename,
    required this.onIconChange,
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
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    topic.icon,
                    style: TextStyle(
                      fontSize: 40,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    topic.name,
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
            Positioned(
              top: 4,
              right: 4,
              child: SizedBox(
                width: 24,
                height: 24,
                child: PopupMenuButton<String>(
                  iconSize: 18,
                  onSelected: (value) {
                    if (value == 'rename') {
                      onRename();
                    } else if (value == 'icon') {
                      onIconChange();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'rename',
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Ubah Nama'),
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'icon',
                          child: ListTile(
                            leading: Icon(Icons.emoji_emotions_outlined),
                            title: Text('Ubah Ikon'),
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
            ),
          ],
        ),
      ),
    );
  }
}
