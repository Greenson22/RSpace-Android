// lib/features/dashboard/presentation/dialogs/progress_settings_dialog.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/core/services/storage_service.dart';
import 'package:my_aplication/features/content_management/domain/models/subject_model.dart';
import 'package:my_aplication/features/content_management/domain/models/topic_model.dart';
import 'package:my_aplication/features/content_management/domain/services/subject_service.dart';
import 'package:my_aplication/features/content_management/domain/services/topic_service.dart';
import 'package:path/path.dart' as path;

void showProgressSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const ProgressSettingsDialog(),
  );
}

class ProgressSettingsDialog extends StatefulWidget {
  const ProgressSettingsDialog({super.key});

  @override
  State<ProgressSettingsDialog> createState() => _ProgressSettingsDialogState();
}

class _ProgressSettingsDialogState extends State<ProgressSettingsDialog> {
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  final TopicService _topicService = TopicService();
  final SubjectService _subjectService = SubjectService();
  final PathService _pathService = PathService();

  bool _isLoading = true;
  Map<Topic, List<Subject>> _allSubjectsByTopic = {};
  Set<String> _excludedSubjectIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final topics = await _topicService.getTopics();
      final topicsPath = await _pathService.topicsPath;
      final tempMap = <Topic, List<Subject>>{};

      for (final topic in topics) {
        if (!topic.isHidden) {
          final topicPath = path.join(topicsPath, topic.name);
          final subjects = await _subjectService.getSubjects(topicPath);
          tempMap[topic] = subjects.where((s) => !s.isHidden).toList();
        }
      }

      final excluded = await _prefsService.loadExcludedSubjects();

      if (mounted) {
        setState(() {
          _allSubjectsByTopic = tempMap;
          _excludedSubjectIds = excluded;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Handle error
      }
    }
  }

  void _onSelectionChanged(bool? value, String subjectId) {
    setState(() {
      if (value == true) {
        _excludedSubjectIds.remove(subjectId);
      } else {
        _excludedSubjectIds.add(subjectId);
      }
    });
  }

  Future<void> _saveSettings() async {
    await _prefsService.saveExcludedSubjects(_excludedSubjectIds.toList());
    if (mounted) {
      Navigator.of(context).pop(true); // Return true to indicate a change
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Atur Perhitungan Progres'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: _allSubjectsByTopic.entries.map((entry) {
                  final topic = entry.key;
                  final subjects = entry.value;
                  if (subjects.isEmpty) return const SizedBox.shrink();
                  return ExpansionTile(
                    key: PageStorageKey(topic.name),
                    title: Text(
                      topic.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: subjects.map((subject) {
                      final subjectId = '${topic.name}/${subject.name}';
                      return CheckboxListTile(
                        title: Text(subject.name),
                        value: !_excludedSubjectIds.contains(subjectId),
                        onChanged: (value) =>
                            _onSelectionChanged(value, subjectId),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(onPressed: _saveSettings, child: const Text('Simpan')),
      ],
    );
  }
}
