// lib/presentation/pages/3_discussions_page/dialogs/move_discussion_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import '../../../../data/models/subject_model.dart';
import '../../../../data/models/topic_model.dart';
import '../../../../data/services/path_service.dart';
import '../../../../data/services/subject_service.dart';
import '../../../../data/services/topic_service.dart';

// ==> Tipe data yang dikembalikan diubah menjadi Map
class MoveDiscussionDialog extends StatefulWidget {
  const MoveDiscussionDialog({super.key});

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
      setState(() {
        _topics = topics.where((t) => !t.isHidden).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  Future<void> _loadSubjects(String topicPath) async {
    setState(() => _isLoading = true);
    try {
      final subjects = await _subjectService.getSubjects(topicPath);
      setState(() {
        _subjects = subjects.where((s) => !s.isHidden).toList();
        _isLoading = false;
      });
    } catch (e) {
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
                          _isTopicView = false;
                        });
                        _loadSubjects(topicPath);
                      },
                    );
                  } else {
                    final subject = _subjects[index];
                    // ==> PERUBAHAN DIMULAI DI SINI <==

                    // Cek apakah subject tujuan memiliki tautan ke PerpusKu.
                    final bool isLinked =
                        subject.linkedPath != null &&
                        subject.linkedPath!.isNotEmpty;

                    return ListTile(
                      enabled:
                          isLinked, // Membuat ListTile bisa diklik atau tidak.
                      leading: Text(
                        subject.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(subject.name),
                      // Tampilkan ikon 'link_off' jika tidak tertaut.
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
                          : null, // Nonaktifkan onTap jika tidak tertaut.
                    );
                    // ==> PERUBAHAN SELESAI DI SINI <==
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
