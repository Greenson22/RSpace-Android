// lib/features/content_management/presentation/subjects/dialogs/move_subject_dialog.dart
import 'package:flutter/material.dart';
import 'package:my_aplication/features/content_management/domain/models/topic_model.dart';
import 'package:my_aplication/features/content_management/domain/services/topic_service.dart';

/// Menampilkan dialog untuk memilih topik tujuan saat memindahkan subject.
/// Mengembalikan objek Topic yang dipilih, atau null jika dibatalkan.
Future<Topic?> showMoveSubjectDialog(
  BuildContext context,
  String currentTopicName,
) async {
  return await showDialog<Topic>(
    context: context,
    builder: (context) => MoveSubjectDialog(currentTopicName: currentTopicName),
  );
}

class MoveSubjectDialog extends StatefulWidget {
  final String currentTopicName;

  const MoveSubjectDialog({super.key, required this.currentTopicName});

  @override
  State<MoveSubjectDialog> createState() => _MoveSubjectDialogState();
}

class _MoveSubjectDialogState extends State<MoveSubjectDialog> {
  final TopicService _topicService = TopicService();
  late Future<List<Topic>> _topicsFuture;

  @override
  void initState() {
    super.initState();
    _topicsFuture = _topicService.getTopics();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pindahkan Subject ke...'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Topic>>(
          future: _topicsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Gagal memuat topik.'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Tidak ada topik lain.'));
            }

            // Saring agar topik saat ini tidak muncul sebagai tujuan
            final destinationTopics = snapshot.data!
                .where(
                  (topic) =>
                      !topic.isHidden && topic.name != widget.currentTopicName,
                )
                .toList();

            if (destinationTopics.isEmpty) {
              return const Center(
                child: Text('Tidak ada topik tujuan yang tersedia.'),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: destinationTopics.length,
              itemBuilder: (context, index) {
                final topic = destinationTopics[index];
                return ListTile(
                  leading: Text(
                    topic.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(topic.name),
                  onTap: () => Navigator.of(context).pop(topic),
                );
              },
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
  }
}
