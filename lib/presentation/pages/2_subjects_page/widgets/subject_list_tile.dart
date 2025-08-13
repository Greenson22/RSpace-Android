import 'package:flutter/material.dart';
import '../../../../data/models/subject_model.dart';
import '../../3_discussions_page/utils/repetition_code_utils.dart'; // DIIMPOR

class SubjectListTile extends StatelessWidget {
  final Subject subject;
  final VoidCallback? onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onIconChange;

  const SubjectListTile({
    super.key,
    required this.subject,
    this.onTap,
    required this.onRename,
    required this.onDelete,
    required this.onIconChange,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Text(subject.icon, style: const TextStyle(fontSize: 24)),
        title: Text(subject.name),
        // ==> SUBTITLE DITAMBAHKAN DI SINI <==
        subtitle: (subject.date != null || subject.repetitionCode != null)
            ? RichText(
                text: TextSpan(
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 12),
                  children: [
                    if (subject.date != null) ...[
                      const TextSpan(text: 'Date: '),
                      TextSpan(
                        text: subject.date,
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    if (subject.repetitionCode != null) ...[
                      const TextSpan(text: ' | Code: '),
                      TextSpan(
                        text: subject.repetitionCode,
                        style: TextStyle(
                          color: getColorForRepetitionCode(
                            subject.repetitionCode!,
                          ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              )
            : null,
        onTap: onTap,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'rename') onRename();
            if (value == 'delete') onDelete();
            if (value == 'change_icon') onIconChange();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'rename', child: Text('Ubah Nama')),
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
