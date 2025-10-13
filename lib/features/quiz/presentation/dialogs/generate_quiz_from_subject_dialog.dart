// lib/features/quiz/presentation/dialogs/generate_quiz_from_subject_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/features/content_management/domain/models/subject_model.dart';
import 'package:my_aplication/features/content_management/domain/services/subject_service.dart';
import 'package:my_aplication/features/content_management/domain/services/topic_service.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import '../../application/quiz_detail_provider.dart';

void showGenerateQuizFromSubjectDialog(BuildContext context) {
  final provider = Provider.of<QuizDetailProvider>(context, listen: false);

  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: const GenerateQuizFromSubjectDialog(),
    ),
  );
}

enum _DialogState { selection, loading }

class GenerateQuizFromSubjectDialog extends StatefulWidget {
  const GenerateQuizFromSubjectDialog({super.key});

  @override
  State<GenerateQuizFromSubjectDialog> createState() =>
      _GenerateQuizFromSubjectDialogState();
}

class _GenerateQuizFromSubjectDialogState
    extends State<GenerateQuizFromSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final TopicService _topicService = TopicService();
  final SubjectService _subjectService = SubjectService();
  final PathService _pathService = PathService();

  final TextEditingController _questionCountController = TextEditingController(
    text: '10',
  );
  String? _selectedTopicName;
  String? _selectedSubjectName;
  QuizDifficulty _selectedDifficulty = QuizDifficulty.medium;

  _DialogState _currentState = _DialogState.selection;

  List<String> _topicNames = [];
  List<Subject> _subjects = [];
  bool _isLoadingSubjects = false;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  @override
  void dispose() {
    _questionCountController.dispose();
    super.dispose();
  }

  Future<void> _loadTopics() async {
    final topics = await _topicService.getTopics();
    if (!mounted) return;
    setState(() {
      _topicNames = topics
          .where((t) => !t.isHidden)
          .map((t) => t.name)
          .toList();
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
      if (!mounted) return;
      setState(() {
        _subjects = subjects.where((s) => !s.isHidden).toList();
        _isLoadingSubjects = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingSubjects = false);
    }
  }

  Future<String?> _showQuizPicker(BuildContext context, List<QuizSet> quizzes) {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Pilih Kuis Tujuan'),
        children: quizzes.isEmpty
            ? [const Center(child: Text("Tidak ada kuis di subjek ini."))]
            : quizzes
                  .map(
                    (quiz) => SimpleDialogOption(
                      onPressed: () => Navigator.pop(dialogContext, quiz.name),
                      child: Text(quiz.name),
                    ),
                  )
                  .toList(),
      ),
    );
  }

  Future<void> _handleAction(bool directImport) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _currentState = _DialogState.loading);

    final provider = Provider.of<QuizDetailProvider>(context, listen: false);
    final topicsPath = await _pathService.topicsPath;
    final subjectJsonPath = path.join(
      topicsPath,
      _selectedTopicName!,
      '$_selectedSubjectName.json',
    );
    final questionCount = int.tryParse(_questionCountController.text) ?? 10;

    try {
      if (directImport) {
        final targetQuizName = await _showQuizPicker(context, provider.quizzes);
        if (targetQuizName != null && mounted) {
          await provider.generateAndAddQuestionsFromRspaceSubject(
            quizSetName: targetQuizName,
            subjectJsonPath: subjectJsonPath,
            questionCount: questionCount,
            difficulty: _selectedDifficulty,
          );
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$questionCount pertanyaan ditambahkan ke "$targetQuizName".',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() => _currentState = _DialogState.selection);
        }
      } else {
        final prompt = await provider.generatePromptFromRspaceSubject(
          subjectJsonPath: subjectJsonPath,
          questionCount: questionCount,
          difficulty: _selectedDifficulty,
        );
        if (mounted) {
          await Clipboard.setData(ClipboardData(text: prompt));
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prompt disalin ke clipboard!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _currentState = _DialogState.selection);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentState == _DialogState.loading) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Membuat pertanyaan..."),
            ],
          ),
        ),
      );
    }

    return AlertDialog(
      title: const Text('Buat Kuis dari Subject R-Space'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<QuizDifficulty>(
                value: _selectedDifficulty,
                decoration: const InputDecoration(
                  labelText: 'Tingkat Kesulitan',
                ),
                items: QuizDifficulty.values.map((difficulty) {
                  return DropdownMenuItem(
                    value: difficulty,
                    child: Text(difficulty.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedDifficulty = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _questionCountController,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Pertanyaan',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah tidak boleh kosong.';
                  }
                  final count = int.tryParse(value);
                  if (count == null || count <= 0) {
                    return 'Masukkan angka yang valid.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTopicName,
                hint: const Text('Pilih Topik Sumber Materi'),
                isExpanded: true,
                items: _topicNames
                    .map(
                      (name) =>
                          DropdownMenuItem(value: name, child: Text(name)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedTopicName = value);
                    _loadSubjects(value);
                  }
                },
                validator: (value) =>
                    value == null ? 'Topik harus dipilih.' : null,
              ),
              const SizedBox(height: 16),
              if (_selectedTopicName != null)
                _isLoadingSubjects
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : DropdownButtonFormField<String>(
                        value: _selectedSubjectName,
                        hint: const Text('Pilih Subject Sumber Materi'),
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
                        validator: (value) =>
                            value == null ? 'Subject harus dipilih.' : null,
                      ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        OutlinedButton(
          onPressed: () => _handleAction(false),
          child: const Text('Buat Prompt Saja'),
        ),
        ElevatedButton(
          onPressed: () => _handleAction(true),
          child: const Text('Buat & Impor'),
        ),
      ],
    );
  }
}
