// lib/features/content_management/presentation/discussions/dialogs/move_discussion_dialog.dart
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../../domain/models/subject_model.dart';
import '../../../domain/models/topic_model.dart';
import '../../../../../core/services/path_service.dart';
import '../../../domain/services/subject_service.dart';
import '../../../domain/services/topic_service.dart';

/// Menampilkan dialog untuk memilih tujuan pemindahan diskusi.
/// Mengembalikan Map berisi 'jsonPath' dan 'linkedPath' jika berhasil.
Future<Map<String, String?>?> showMoveDiscussionDialog(
  BuildContext context,
  String currentSubjectName, // Terima nama Subject asal
) async {
  // === Ambil Topic asal dari SubjectService atau provider jika memungkinkan ===
  // Untuk contoh ini, kita asumsikan topicName bisa didapatkan dari context atau argument lain jika perlu
  // Jika tidak, kita perlu cara lain untuk mendapatkannya agar perbandingan lebih akurat.
  // Misalnya, DiscussionProvider bisa menyimpannya.
  // Untuk sementara, kita asumsikan kita punya topicName asal.
  // Jika Anda menggunakan Provider, Anda bisa ambil dari sana:
  // final currentTopicName = Provider.of<DiscussionProvider>(context, listen: false).subject.topicName;

  // Jika tidak, kita perlu modifikasi lebih lanjut untuk mendapatkan nama Topic asal.
  // Untuk sementara kita pakai asumsi kasar (ini mungkin perlu disesuaikan):
  String? currentTopicName; // Inisialisasi null
  try {
    // Mencoba mencari topicName berdasarkan subjectName (mungkin tidak selalu akurat jika ada nama subject sama di topik berbeda)
    final topicService = TopicService();
    final pathService = PathService();
    final topicsPath = await pathService.topicsPath;
    final topics = await topicService.getTopics();
    for (var topic in topics) {
      final topicPath = path.join(topicsPath, topic.name);
      final subjectService = SubjectService();
      final subjects = await subjectService.getSubjects(topicPath);
      if (subjects.any((s) => s.name == currentSubjectName)) {
        currentTopicName = topic.name;
        break;
      }
    }
  } catch (e) {
    print("Error getting current topic name: $e");
    currentTopicName = null; // Gagal mendapatkan nama topik
  }

  return await showDialog<Map<String, String?>?>(
    context: context,
    builder: (context) => MoveDiscussionDialog(
      currentSubjectName: currentSubjectName,
      // === Kirim juga nama Topic asal ===
      currentTopicName: currentTopicName,
    ),
  );
}

class MoveDiscussionDialog extends StatefulWidget {
  final String currentSubjectName;
  // === Tambahkan properti untuk nama Topic asal ===
  final String? currentTopicName;

  const MoveDiscussionDialog({
    super.key,
    required this.currentSubjectName,
    this.currentTopicName, // Terima nama Topic asal
  });

  @override
  State<MoveDiscussionDialog> createState() => _MoveDiscussionDialogState();
}

class _MoveDiscussionDialogState extends State<MoveDiscussionDialog> {
  final PathService _pathService = PathService();
  final TopicService _topicService = TopicService();
  final SubjectService _subjectService = SubjectService();

  List<Topic> _topics = [];
  List<Subject> _subjects = [];
  bool _isLoading = true;
  String? _selectedTopicPath;
  Topic? _selectedTopic; // Simpan objek Topic yang dipilih
  bool _isTopicView = true;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() => _isLoading = true);
    try {
      final topics = await _topicService.getTopics();
      if (!mounted) return;
      setState(() {
        _topics = topics.where((t) => !t.isHidden).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error memuat topik: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadSubjects(String topicPath) async {
    setState(() => _isLoading = true);
    try {
      // Dapatkan subject, termasuk topicName di dalamnya
      final subjects = await _subjectService.getSubjects(topicPath);
      if (!mounted) return;
      setState(() {
        // Filter subject yang tidak hidden
        _subjects = subjects.where((s) => !s.isHidden).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error memuat subject: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isTopicView ? 'Pilih Topik Tujuan' : 'Pilih Subjek Tujuan'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _isTopicView ? _topics.length : _subjects.length,
                itemBuilder: (context, index) {
                  if (_isTopicView) {
                    final topic = _topics[index];
                    return ListTile(
                      leading: Text(
                        topic.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(topic.name),
                      onTap: () async {
                        final topicsPath = await _pathService.topicsPath;
                        final topicPath = path.join(topicsPath, topic.name);
                        setState(() {
                          _selectedTopicPath = topicPath;
                          _selectedTopic = topic; // Simpan Topic yang dipilih
                          _isTopicView = false;
                        });
                        _loadSubjects(topicPath);
                      },
                    );
                  } else {
                    final subject = _subjects[index];
                    final bool isLinked =
                        subject.linkedPath != null &&
                        subject.linkedPath!.isNotEmpty;

                    // === PERUBAHAN LOGIKA FILTER DI SINI ===
                    // Cek apakah ini adalah subject asal
                    final bool isSourceSubject =
                        _selectedTopic != null &&
                        _selectedTopic!.name ==
                            widget
                                .currentTopicName && // Bandingkan nama topiknya juga
                        subject.name == widget.currentSubjectName;
                    // === AKHIR PERUBAHAN LOGIKA FILTER ===

                    return ListTile(
                      // Nonaktifkan jika tidak linked ATAU jika ini adalah subject asal
                      enabled: isLinked && !isSourceSubject,
                      leading: Text(
                        subject.icon,
                        style: TextStyle(
                          fontSize: 24,
                          // Beri warna abu-abu jika subject asal
                          color: isSourceSubject ? Colors.grey : null,
                        ),
                      ),
                      title: Text(
                        subject.name,
                        style: TextStyle(
                          // Beri warna abu-abu jika subject asal
                          color: isSourceSubject ? Colors.grey : null,
                        ),
                      ),
                      trailing: !isLinked
                          ? const Icon(Icons.link_off, color: Colors.grey)
                          // Tampilkan indikator jika subject asal
                          : isSourceSubject
                          ? const Text(
                              "(Asal)",
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : null,
                      onTap:
                          (isLinked &&
                              !isSourceSubject) // Hanya bisa tap jika linked DAN bukan subject asal
                          ? () {
                              final subjectJsonPath = path.join(
                                _selectedTopicPath!,
                                '${subject.name}.json',
                              );
                              final Map<String, String?> result = {
                                'jsonPath': subjectJsonPath,
                                'linkedPath': subject.linkedPath,
                              };
                              Navigator.of(context).pop(result);
                            }
                          : null, // onTap null jika tidak aktif
                    );
                  }
                },
              ),
      ),
      actions: [
        if (!_isTopicView)
          TextButton(
            onPressed: () {
              setState(() {
                _isTopicView = true;
                _selectedTopicPath = null;
                _selectedTopic = null; // Reset Topic yang dipilih
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
}
