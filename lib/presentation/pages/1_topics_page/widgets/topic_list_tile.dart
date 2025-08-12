import 'package:flutter/material.dart';
import '../../../../data/models/topic_model.dart';

class TopicListTile extends StatelessWidget {
  final Topic topic;
  final VoidCallback? onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onIconChange;
  final bool isReorderActive;

  const TopicListTile({
    super.key,
    required this.topic,
    this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onIconChange,
    this.isReorderActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(topic.icon, style: const TextStyle(fontSize: 24)),
        title: Text(topic.name),
        onTap: onTap,
        trailing: isReorderActive
            ? null
            : PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'rename') onRename();
                  if (value == 'delete') onDelete();
                  if (value == 'change_icon') onIconChange();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Text('Ubah Nama'),
                  ),
                  const PopupMenuItem(
                    value: 'change_icon',
                    child: Text('Ubah Ikon'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
      ),
    );
  }
}
