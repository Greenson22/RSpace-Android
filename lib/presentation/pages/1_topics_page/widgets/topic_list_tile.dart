import 'package:flutter/material.dart';
import '../../../../data/models/topic_model.dart'; // ==> DITAMBAHKAN

class TopicListTile extends StatelessWidget {
  final Topic topic; // ==> DIGANTI DARI String ke Topic
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onIconChange; // ==> DITAMBAHKAN

  const TopicListTile({
    super.key,
    required this.topic, // ==> DIGANTI
    required this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onIconChange, // ==> DITAMBAHKAN
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        // ==> LEADING DIUBAH UNTUK MENAMPILKAN IKON <==
        leading: Text(topic.icon, style: const TextStyle(fontSize: 24)),
        title: Text(topic.name), // ==> MENGGUNAKAN topic.name
        onTap: onTap,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'rename') onRename();
            if (value == 'delete') onDelete();
            if (value == 'change_icon') onIconChange(); // ==> DITAMBAHKAN
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'rename', child: Text('Ubah Nama')),
            // ==> MENU BARU DITAMBAHKAN <==
            const PopupMenuItem(value: 'change_icon', child: Text('Ubah Ikon')),
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
