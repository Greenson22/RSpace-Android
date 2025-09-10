// lib/features/quiz/presentation/dialogs/add_quiz_dialog.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/features/content_management/domain/models/subject_model.dart';
import 'package:my_aplication/features/content_management/domain/services/subject_service.dart';
import 'package:my_aplication/features/content_management/domain/services/topic_service.dart';
import 'package:provider/provider.dart';
import '../../application/quiz_detail_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart'; // Import untuk input formatter

void showAddQuizDialog(BuildContext context) {
  // Mengambil provider dari context Halaman Detail
  final provider = Provider.of<QuizDetailProvider>(context, listen: false);

  showDialog(
    context: context,
    // Gunakan builder agar dialog tidak full-screen di layar kecil
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
  final _formKey = GlobalKey<FormState>();
  final TopicService _topicService = TopicService();
  final SubjectService _subjectService = SubjectService();
  final PathService _pathService = PathService();

  // State untuk mengelola pilihan dropdown dan text field
  final TextEditingController _quizSetNameController = TextEditingController();
  // ==> TAMBAHKAN CONTROLLER BARU UNTUK JUMLAH PERTANYAAN <==
  final TextEditingController _questionCountController = TextEditingController(
    text: '10',
  );
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

  @override
  void dispose() {
    _quizSetNameController.dispose();
    // ==> JANGAN LUPA DISPOSE CONTROLLER BARU <==
    _questionCountController.dispose();
    super.dispose();
  }

  Future<void> _loadTopics() async {
    setState(() => _isLoadingTopics = true);
    final topics = await _topicService.getTopics();
    if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _subjects = subjects.where((s) => !s.isHidden).toList();
        _isLoadingSubjects = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingSubjects = false);
      // Handle error
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
    // ==> PARSE JUMLAH PERTANYAAN <==
    final questionCount = int.tryParse(_questionCountController.text) ?? 10;

    // Tutup dialog saat proses dimulai
    Navigator.of(context).pop();

    try {
      // ==> KIRIM JUMLAH PERTANYAAN KE PROVIDER <==
      await provider.addQuizSetFromSubject(
        quizSetName,
        subjectJsonPath,
        questionCount,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kuis baru berhasil dibuat!'),
            backgroundColor: Colors.green,
          ),
        );
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
    return AlertDialog(
      title: const Text('Buat Kuis dengan AI'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih materi dari "Topics" untuk dibuatkan soal kuis secara otomatis oleh AI.',
              ),
              const SizedBox(height: 24),
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
              // ==> TAMBAHKAN INPUT FIELD UNTUK JUMLAH PERTANYAAN <==
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
                            setState(() {
                              _selectedSubjectName = value;
                              // Otomatis isi nama kuis jika kosong
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
          child: const Text('Buat Pertanyaan'),
        ),
      ],
    );
  }
}
