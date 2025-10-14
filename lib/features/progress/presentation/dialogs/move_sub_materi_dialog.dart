// lib/features/progress/presentation/dialogs/move_sub_materi_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/progress_detail_provider.dart';
import '../../domain/models/progress_subject_model.dart';

Future<ProgressSubject?> showMoveSubMateriDialog(
  BuildContext context,
  ProgressSubject currentSubject,
) {
  final provider = Provider.of<ProgressDetailProvider>(context, listen: false);
  return showDialog<ProgressSubject>(
    context: context,
    builder: (context) {
      final destinationSubjects = provider.topic.subjects
          .where((s) => s != currentSubject)
          .toList();

      return AlertDialog(
        title: const Text('Pindahkan ke Materi...'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: destinationSubjects.length,
            itemBuilder: (context, index) {
              final subject = destinationSubjects[index];
              return ListTile(
                leading: Text(
                  subject.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(subject.namaMateri),
                onTap: () => Navigator.of(context).pop(subject),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
        ],
      );
    },
  );
}
