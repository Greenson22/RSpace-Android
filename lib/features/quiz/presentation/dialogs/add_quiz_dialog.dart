// lib/features/quiz/presentation/dialogs/add_quiz_dialog.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/features/content_management/domain/models/subject_model.dart';
import 'package:my_aplication/features/content_management/domain/services/subject_service.dart';
import 'package:my_aplication/features/content_management/domain/services/topic_service.dart';
import 'package:provider/provider.dart';
import '../../application/quiz_detail_provider.dart';
import 'package:path/path.dart' as path;

void showAddQuizDialog(BuildContext context) {
  // Mengambil provider dari context Halaman Detail
  final provider = Provider.of<QuizDetailProvider>(context, listen: false);

  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: const AddQuizDialog(),
    ),
  );
}

class AddQuizDialog extends StatefulWidget {
  const AddQuizDialog({super.key});

  @override
  State<AddQuizDialog> createState() => _AddQuizDialogState();
}

class _AddQuizDialogState extends State<AddQuizDialog> {
  final TopicService _topicService = TopicService();
  final SubjectService _subjectService = SubjectService();
  final PathService _pathService = PathService();

  // State untuk mengelola pilihan dropdown
  String? _selectedTopicName;
  String? _selectedSubjectName;
  List<String> _topicNames = [];
  List<Subject> _subjects = [];
  bool _isLoadingTopics = true;
  bool _isLoadingSubjects = false;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() => _isLoadingTopics = true);
    final topics = await _topicService.getTopics();
    setState(() {
      _topicNames = topics
          .where((t) => !t.isHidden)
          .map((t) => t.name)
          .toList();
      _isLoadingTopics = false;
    });
  }

  Future<void> _loadSubjects(String topicName) async {
    setState(() {
      _isLoadingSubjects = true;
      _subjects = [];
      _selectedSubjectName = null;
    });
    try {
      final topicsPath = await _pathService.topicsPath;
      final topicPath = path.join(topicsPath, topicName);
      final subjects = await _subjectService.getSubjects(topicPath);
      setState(() {
        _subjects = subjects.where((s) => !s.isHidden).toList();
        _isLoadingSubjects = false;
      });
    } catch (e) {
      setState(() => _isLoadingSubjects = false);
      // Handle error
    }
  }

  Future<void> _handleGenerate() async {
    if (_selectedTopicName == null || _selectedSubjectName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih Topik dan Subject terlebih dahulu.'),
        ),
      );
      return;
    }

    final provider = Provider.of<QuizDetailProvider>(context, listen: false);
    final topicsPath = await _pathService.topicsPath;
    final subjectJsonPath = path.join(
      topicsPath,
      _selectedTopicName!,
      '$_selectedSubjectName.json',
    );

    // Tutup dialog saat proses dimulai
    Navigator.of(context).pop();

    try {
      await provider.addQuestionsFromSubject(subjectJsonPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buat Kuis dengan AI'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih materi dari "Topics" untuk dibuatkan soal kuis secara otomatis oleh AI.',
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedTopicName,
              hint: const Text('Pilih Topik...'),
              isExpanded: true,
              items: _topicNames
                  .map(
                    (name) => DropdownMenuItem(value: name, child: Text(name)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTopicName = value);
                  _loadSubjects(value);
                }
              },
            ),
            const SizedBox(height: 16),
            if (_selectedTopicName != null)
              _isLoadingSubjects
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: _selectedSubjectName,
                      hint: const Text('Pilih Subject...'),
                      isExpanded: true,
                      items: _subjects
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.name,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedSubjectName = value);
                        }
                      },
                    ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _handleGenerate,
          child: const Text('Buat Pertanyaan'),
        ),
      ],
    );
  }
}
