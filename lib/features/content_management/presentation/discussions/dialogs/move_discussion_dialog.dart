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
  // === 1. TAMBAHKAN PARAMETER BARU ===
  String currentSubjectName,
) async {
  return await showDialog<Map<String, String?>?>(
    context: context,
    builder: (context) => MoveDiscussionDialog(
      // === 2. KIRIM PARAMETER KE WIDGET ===
      currentSubjectName: currentSubjectName,
    ),
  );
}

class MoveDiscussionDialog extends StatefulWidget {
  // === 3. TAMBAHKAN PROPERTI BARU ===
  final String currentSubjectName;

  const MoveDiscussionDialog({super.key, required this.currentSubjectName});

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
    }
  }

  Future<void> _loadSubjects(String topicPath) async {
    setState(() => _isLoading = true);
    try {
      final subjects = await _subjectService.getSubjects(topicPath);
      if (!mounted) return;
      setState(() {
        _subjects = subjects.where((s) => !s.isHidden).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Handle error
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

                    // === 4. TAMBAHKAN KONDISI FILTER DI SINI ===
                    // Jangan tampilkan subject jika namanya sama dengan subject asal
                    // DAN topiknya juga sama dengan topik asal (jika _selectedTopic tersedia)
                    if (_selectedTopic != null &&
                        _selectedTopic!.name == subject.topicName &&
                        subject.name == widget.currentSubjectName) {
                      return const SizedBox.shrink(); // Jangan tampilkan ListTile
                    }
                    // === AKHIR KONDISI FILTER ===

                    return ListTile(
                      enabled: isLinked,
                      leading: Text(
                        subject.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(subject.name),
                      trailing: !isLinked
                          ? const Icon(Icons.link_off, color: Colors.grey)
                          : null,
                      onTap: isLinked
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
                          : null,
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
