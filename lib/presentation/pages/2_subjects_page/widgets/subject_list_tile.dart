import 'package:flutter/material.dart';

class SubjectListTile extends StatelessWidget {
  final String subjectName;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const SubjectListTile({
    super.key,
    required this.subjectName,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.description, color: Colors.orange),
        title: Text(subjectName),
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
