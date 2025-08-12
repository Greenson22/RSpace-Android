import 'package:flutter/material.dart';

class TopicListTile extends StatelessWidget {
  final String topicName;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const TopicListTile({
    super.key,
    required this.topicName,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.folder_open, color: Colors.teal),
        title: Text(topicName),
        onTap: onTap,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'rename') onRename();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'rename', child: Text('Ubah Nama')),
            const PopupMenuItem(value: 'delete', child: Text('Hapus')),
          ],
        ),
      ),
    );
  }
}
