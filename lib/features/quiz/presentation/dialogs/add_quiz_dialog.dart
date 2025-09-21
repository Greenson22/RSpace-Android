// lib/features/quiz/presentation/dialogs/add_quiz_dialog.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/features/content_management/domain/models/subject_model.dart';
import 'package:my_aplication/features/content_management/domain/services/subject_service.dart';
import 'package:my_aplication/features/content_management/domain/services/topic_service.dart';
import 'package:my_aplication/features/quiz/domain/models/quiz_model.dart';
import 'package:provider/provider.dart';
import '../../application/quiz_detail_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart'; // Import untuk input formatter

// ==> FUNGSI DIPERBARUI UNTUK MENERIMA QUIZSET OPSIONAL
void showAddQuizDialog(BuildContext context, {QuizSet? existingQuizSet}) {
  final provider = Provider.of<QuizDetailProvider>(context, listen: false);

  showDialog(
    context: context,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      // ==> KIRIM QUIZSET KE DIALOG
      child: AddQuizDialog(existingQuizSet: existingQuizSet),
    ),
  );
}

class AddQuizDialog extends StatefulWidget {
  // ==> TAMBAHKAN PROPERTI BARU
  final QuizSet? existingQuizSet;
  const AddQuizDialog({super.key, this.existingQuizSet});

  @override
  State<AddQuizDialog> createState() => _AddQuizDialogState();
}

class _AddQuizDialogState extends State<AddQuizDialog> {
  final _formKey = GlobalKey<FormState>();
  final TopicService _topicService = TopicService();
  final SubjectService _subjectService = SubjectService();
  final PathService _pathService = PathService();

  final TextEditingController _quizSetNameController = TextEditingController();
  final TextEditingController _questionCountController = TextEditingController(
    text: '10',
  );
  String? _selectedTopicName;
  String? _selectedSubjectName;
  QuizDifficulty _selectedDifficulty = QuizDifficulty.medium;
  List<String> _topicNames = [];
  List<Subject> _subjects = [];
  bool _isLoadingSubjects = false;

  // ==> TENTUKAN APAKAH INI MODE TAMBAH PERTANYAAN
  bool get isAddingQuestionsMode => widget.existingQuizSet != null;

  @override
  void initState() {
    super.initState();
    _loadTopics();
    // Jika dalam mode edit, isi nama set kuis secara otomatis
    if (isAddingQuestionsMode) {
      _quizSetNameController.text = widget.existingQuizSet!.name;
    }
  }

  @override
  void dispose() {
    _quizSetNameController.dispose();
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

  Future<void> _handleGenerate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = Provider.of<QuizDetailProvider>(context, listen: false);
    final topicsPath = await _pathService.topicsPath;
    final subjectJsonPath = path.join(
      topicsPath,
      _selectedTopicName!,
      '$_selectedSubjectName.json',
    );
    final quizSetName = _quizSetNameController.text.trim();
    final questionCount = int.tryParse(_questionCountController.text) ?? 10;

    Navigator.of(context).pop();

    try {
      // ==> GUNAKAN LOGIKA KONDISIONAL DI SINI
      if (isAddingQuestionsMode) {
        await provider.addQuestionsToQuizSetFromSubject(
          quizSetName: quizSetName,
          subjectJsonPath: subjectJsonPath,
          questionCount: questionCount,
          difficulty: _selectedDifficulty,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pertanyaan baru berhasil ditambahkan!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await provider.addQuizSetFromSubject(
          quizSetName,
          subjectJsonPath,
          questionCount,
          _selectedDifficulty,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kuis baru berhasil dibuat!'),
              backgroundColor: Colors.green,
            ),
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ==> SESUAIKAN JUDUL DIALOG
    final dialogTitle = isAddingQuestionsMode
        ? 'Tambah Pertanyaan ke "${widget.existingQuizSet!.name}"'
        : 'Buat Kuis dengan AI';

    return AlertDialog(
      title: Text(dialogTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAddingQuestionsMode
                    ? 'Pilih sumber materi untuk pertanyaan tambahan.'
                    : 'Pilih materi dari "Topics" untuk dibuatkan soal kuis secara otomatis oleh AI.',
              ),
              const SizedBox(height: 24),
              // ==> SEMBUNYIKAN INPUT NAMA JIKA MODE TAMBAH PERTANYAAN
              if (!isAddingQuestionsMode)
                TextFormField(
                  controller: _quizSetNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Set Kuis (contoh: Kuis Bab 1)',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama set kuis tidak boleh kosong.';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
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
                decoration: InputDecoration(
                  labelText: isAddingQuestionsMode
                      ? 'Jumlah Pertanyaan Tambahan'
                      : 'Jumlah Pertanyaan',
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
                            setState(() {
                              _selectedSubjectName = value;
                              if (_quizSetNameController.text.trim().isEmpty) {
                                _quizSetNameController.text =
                                    "Kuis tentang $value";
                              }
                            });
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
        ElevatedButton(
          onPressed: _handleGenerate,
          // ==> SESUAIKAN TEKS TOMBOL
          child: Text(
            isAddingQuestionsMode ? 'Generate & Tambahkan' : 'Buat Pertanyaan',
          ),
        ),
      ],
    );
  }
}
