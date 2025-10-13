// lib/features/perpusku/presentation/dialogs/perpusku_quiz_picker_dialog.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/perpusku/application/perpusku_quiz_service.dart';
import 'package:my_aplication/features/perpusku/domain/models/perpusku_models.dart';
import 'package:my_aplication/features/perpusku/domain/models/quiz_model.dart';
import 'package:my_aplication/features/perpusku/infrastructure/perpusku_service.dart';
import 'package:path/path.dart' as path;

// Class untuk menampung hasil pemilihan
class PerpuskuQuizPickerResult {
  final String subjectPath; // e.g., "Topik A/Subjek B"
  final String quizName;

  PerpuskuQuizPickerResult({required this.subjectPath, required this.quizName});
}

// Fungsi untuk menampilkan dialog
Future<PerpuskuQuizPickerResult?> showPerpuskuQuizPickerDialog(
  BuildContext context,
) async {
  return await showDialog<PerpuskuQuizPickerResult>(
    context: context,
    builder: (context) => const PerpuskuQuizPickerDialog(),
  );
}

enum _PickerViewState { topics, subjects, quizzes }

class PerpuskuQuizPickerDialog extends StatefulWidget {
  const PerpuskuQuizPickerDialog({super.key});

  @override
  State<PerpuskuQuizPickerDialog> createState() =>
      _PerpuskuQuizPickerDialogState();
}

class _PerpuskuQuizPickerDialogState extends State<PerpuskuQuizPickerDialog> {
  final PerpuskuService _perpuskuService = PerpuskuService();
  final PerpuskuQuizService _quizService = PerpuskuQuizService();

  _PickerViewState _currentView = _PickerViewState.topics;
  bool _isLoading = true;

  List<PerpuskuTopic> _topics = [];
  List<PerpuskuSubject> _subjects = [];
  List<QuizSet> _quizzes = [];

  PerpuskuTopic? _selectedTopic;
  PerpuskuSubject? _selectedSubject;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() => _isLoading = true);
    _topics = await _perpuskuService.getTopics();
    setState(() => _isLoading = false);
  }

  Future<void> _loadSubjects(PerpuskuTopic topic) async {
    setState(() {
      _isLoading = true;
      _selectedTopic = topic;
    });
    _subjects = await _perpuskuService.getSubjects(topic.path);
    setState(() {
      _isLoading = false;
      _currentView = _PickerViewState.subjects;
    });
  }

  Future<void> _loadQuizzes(PerpuskuSubject subject) async {
    setState(() {
      _isLoading = true;
      _selectedSubject = subject;
    });
    final pathParts = subject.path.split('/');
    final relativeSubjectPath = pathParts
        .sublist(pathParts.length - 2)
        .join('/');
    _quizzes = await _quizService.loadQuizzes(relativeSubjectPath);
    setState(() {
      _isLoading = false;
      _currentView = _PickerViewState.quizzes;
    });
  }

  String _getTitle() {
    switch (_currentView) {
      case _PickerViewState.topics:
        return 'Pilih Topik';
      case _PickerViewState.subjects:
        return 'Pilih Subjek';
      case _PickerViewState.quizzes:
        return 'Pilih Kuis';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_getTitle()),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildCurrentView(),
      ),
      actions: [
        if (_currentView != _PickerViewState.topics)
          TextButton(
            onPressed: () {
              setState(() {
                if (_currentView == _PickerViewState.quizzes) {
                  _currentView = _PickerViewState.subjects;
                } else if (_currentView == _PickerViewState.subjects) {
                  _currentView = _PickerViewState.topics;
                }
              });
            },
            child: const Text('Kembali'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case _PickerViewState.topics:
        return ListView.builder(
          itemCount: _topics.length,
          itemBuilder: (context, index) {
            final topic = _topics[index];
            return ListTile(
              leading: Text(topic.icon, style: const TextStyle(fontSize: 24)),
              title: Text(topic.name),
              onTap: () => _loadSubjects(topic),
            );
          },
        );
      case _PickerViewState.subjects:
        return ListView.builder(
          itemCount: _subjects.length,
          itemBuilder: (context, index) {
            final subject = _subjects[index];
            return ListTile(
              leading: Text(subject.icon, style: const TextStyle(fontSize: 24)),
              title: Text(subject.name),
              onTap: () => _loadQuizzes(subject),
            );
          },
        );
      case _PickerViewState.quizzes:
        if (_quizzes.isEmpty) {
          return const Center(child: Text('Tidak ada kuis di subjek ini.'));
        }
        return ListView.builder(
          itemCount: _quizzes.length,
          itemBuilder: (context, index) {
            final quiz = _quizzes[index];
            return ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: Text(quiz.name),
              subtitle: Text('${quiz.questions.length} pertanyaan'),
              onTap: () {
                final pathParts = _selectedSubject!.path.split('/');
                final relativeSubjectPath = pathParts
                    .sublist(pathParts.length - 2)
                    .join('/');
                Navigator.of(context).pop(
                  PerpuskuQuizPickerResult(
                    subjectPath: relativeSubjectPath,
                    quizName: quiz.name,
                  ),
                );
              },
            );
          },
        );
    }
  }
}
