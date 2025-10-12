// lib/features/perpusku/presentation/dialogs/generate_perpusku_quiz_prompt_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/features/content_management/domain/models/subject_model.dart';
import 'package:my_aplication/features/content_management/domain/services/subject_service.dart';
import 'package:my_aplication/features/content_management/domain/services/topic_service.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import '../../application/perpusku_quiz_detail_provider.dart';

void showGeneratePerpuskuQuizPromptDialog(BuildContext context) {
  final provider = Provider.of<PerpuskuQuizDetailProvider>(
    context,
    listen: false,
  );

  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: const GeneratePerpuskuQuizPromptDialog(),
    ),
  );
}

enum _PromptDialogState { selection, prompt, loading }

class GeneratePerpuskuQuizPromptDialog extends StatefulWidget {
  const GeneratePerpuskuQuizPromptDialog({super.key});

  @override
  State<GeneratePerpuskuQuizPromptDialog> createState() =>
      _GeneratePerpuskuQuizPromptDialogState();
}

class _GeneratePerpuskuQuizPromptDialogState
    extends State<GeneratePerpuskuQuizPromptDialog> {
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

  _PromptDialogState _currentState = _PromptDialogState.selection;
  String _generatedPrompt = '';

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

  Future<void> _handleGeneratePrompt() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _currentState = _PromptDialogState.loading);

    final provider = Provider.of<PerpuskuQuizDetailProvider>(
      context,
      listen: false,
    );
    final topicsPath = await _pathService.topicsPath;
    final subjectJsonPath = path.join(
      topicsPath,
      _selectedTopicName!,
      '$_selectedSubjectName.json',
    );
    final questionCount = int.tryParse(_questionCountController.text) ?? 10;

    try {
      final prompt = await provider.generatePromptFromRspaceSubject(
        subjectJsonPath: subjectJsonPath,
        questionCount: questionCount,
        difficulty: _selectedDifficulty,
      );
      if (mounted) {
        setState(() {
          _generatedPrompt = prompt;
          _currentState = _PromptDialogState.prompt;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _currentState = _PromptDialogState.selection);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _currentState == _PromptDialogState.selection
            ? 'Buat Prompt dari Subject R-Space'
            : 'Salin Prompt Ini',
      ),
      content: _buildContent(),
      actions: _buildActions(),
    );
  }

  Widget _buildContent() {
    switch (_currentState) {
      case _PromptDialogState.selection:
        return _buildSelectionForm();
      case _PromptDialogState.loading:
        return const Center(child: CircularProgressIndicator());
      case _PromptDialogState.prompt:
        return _buildPromptDisplay();
    }
  }

  List<Widget> _buildActions() {
    switch (_currentState) {
      case _PromptDialogState.selection:
        return [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _handleGeneratePrompt,
            child: const Text('Buat Prompt'),
          ),
        ];
      case _PromptDialogState.loading:
        return [];
      case _PromptDialogState.prompt:
        return [
          TextButton(
            onPressed: () =>
                setState(() => _currentState = _PromptDialogState.selection),
            child: const Text('Kembali'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Salin'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _generatedPrompt));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prompt disalin ke clipboard!')),
              );
            },
          ),
        ];
    }
  }

  Widget _buildSelectionForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<QuizDifficulty>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(labelText: 'Tingkat Kesulitan'),
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
              decoration: const InputDecoration(labelText: 'Jumlah Pertanyaan'),
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
                    (name) => DropdownMenuItem(value: name, child: Text(name)),
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
    );
  }

  Widget _buildPromptDisplay() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(_generatedPrompt),
      ),
    );
  }
}
