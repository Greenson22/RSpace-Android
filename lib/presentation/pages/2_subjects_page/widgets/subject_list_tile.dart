import 'package:flutter/material.dart';
import '../../../../data/models/subject_model.dart'; // ==> DITAMBAHKAN

class SubjectListTile extends StatelessWidget {
  final Subject subject; // ==> DIGANTI DARI String ke Subject
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onIconChange; // ==> DITAMBAHKAN

  const SubjectListTile({
    super.key,
    required this.subject, // ==> DIGANTI
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
        leading: Text(subject.icon, style: const TextStyle(fontSize: 24)),
        title: Text(subject.name), // ==> MENGGUNAKAN subject.name
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
