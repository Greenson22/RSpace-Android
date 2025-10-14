// lib/features/progress/presentation/dialogs/move_sub_materi_topic_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/progress_provider.dart';
import '../../domain/models/progress_subject_model.dart';
import '../../domain/models/progress_topic_model.dart';

// Class untuk menampung hasil
class MoveSubMateriResult {
  final ProgressTopic topic;
  final ProgressSubject subject;

  MoveSubMateriResult({required this.topic, required this.subject});
}

// Fungsi untuk menampilkan dialog
Future<MoveSubMateriResult?> showMoveSubMateriToTopicDialog(
  BuildContext context,
) {
  return showDialog<MoveSubMateriResult>(
    context: context,
    builder: (context) => ChangeNotifierProvider(
      create: (_) => ProgressProvider(),
      child: const MoveSubMateriToTopicDialog(),
    ),
  );
}

enum _MoveViewState { topic, subject }

class MoveSubMateriToTopicDialog extends StatefulWidget {
  const MoveSubMateriToTopicDialog({super.key});

  @override
  State<MoveSubMateriToTopicDialog> createState() =>
      _MoveSubMateriToTopicDialogState();
}

class _MoveSubMateriToTopicDialogState
    extends State<MoveSubMateriToTopicDialog> {
  _MoveViewState _currentView = _MoveViewState.topic;
  ProgressTopic? _selectedTopic;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProgressProvider>(context);

    return AlertDialog(
      title: Text(
        _currentView == _MoveViewState.topic
            ? 'Pilih Topik Tujuan'
            : 'Pilih Materi Tujuan',
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildCurrentView(provider),
      ),
      actions: [
        if (_currentView == _MoveViewState.subject)
          TextButton(
            onPressed: () =>
                setState(() => _currentView = _MoveViewState.topic),
            child: const Text('Kembali'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
    );
  }

  Widget _buildCurrentView(ProgressProvider provider) {
    if (_currentView == _MoveViewState.topic) {
      return ListView.builder(
        itemCount: provider.topics.length,
        itemBuilder: (context, index) {
          final topic = provider.topics[index];
          return ListTile(
            leading: Text(topic.icon, style: const TextStyle(fontSize: 24)),
            title: Text(topic.topics),
            onTap: () {
              setState(() {
                _selectedTopic = topic;
                _currentView = _MoveViewState.subject;
              });
            },
          );
        },
      );
    } else {
      return ListView.builder(
        itemCount: _selectedTopic!.subjects.length,
        itemBuilder: (context, index) {
          final subject = _selectedTopic!.subjects[index];
          return ListTile(
            leading: Text(subject.icon, style: const TextStyle(fontSize: 24)),
            title: Text(subject.namaMateri),
            onTap: () {
              Navigator.of(context).pop(
                MoveSubMateriResult(topic: _selectedTopic!, subject: subject),
              );
            },
          );
        },
      );
    }
  }
}
