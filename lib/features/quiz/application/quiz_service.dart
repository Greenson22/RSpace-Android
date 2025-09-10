// lib/features/quiz/application/quiz_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:my_aplication/core/services/path_service.dart';
import '../domain/models/quiz_model.dart';

class QuizService {
  final PathService _pathService = PathService();
  static const String _defaultIcon = '❓';
  static const String _configFile = 'quiz_topic_config.json';

  Future<String> get _quizPath async {
    final dirPath = await _pathService.quizPath;
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dirPath;
  }

  Future<QuizTopic> getTopic(String topicName) async {
    final quizzesPath = await _quizPath;
    final topicPath = path.join(quizzesPath, topicName);
    final configFile = File(path.join(topicPath, _configFile));

    if (!await configFile.exists()) {
      throw Exception('File konfigurasi untuk $topicName tidak ditemukan.');
    }

    final configString = await configFile.readAsString();
    final configJson = jsonDecode(configString) as Map<String, dynamic>;

    return QuizTopic.fromConfig(topicName, configJson);
  }

  Future<List<QuizSet>> getQuizSetsInTopic(String topicName) async {
    final quizzesPath = await _quizPath;
    final topicPath = path.join(quizzesPath, topicName);
    final directory = Directory(topicPath);

    if (!await directory.exists()) return [];

    final files = directory.listSync().whereType<File>().where(
      (file) =>
          file.path.endsWith('.json') &&
          path.basename(file.path) != _configFile,
    );

    List<QuizSet> quizSets = [];
    for (final file in files) {
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final quizSetName = path.basenameWithoutExtension(file.path);
      quizSets.add(QuizSet.fromJson(quizSetName, jsonData));
    }
    return quizSets;
  }

  Future<List<QuizQuestion>> getAllQuestionsInTopic(QuizTopic topic) async {
    final List<QuizQuestion> allQuestions = [];
    final quizSets = await getQuizSetsInTopic(topic.name);

    // Filter hanya set kuis yang diikutkan
    final includedSets = quizSets.where(
      (set) => topic.includedQuizSets.contains(set.name),
    );

    for (final quizSet in includedSets) {
      allQuestions.addAll(quizSet.questions);
    }

    // Acak jika diatur
    if (topic.shuffleQuestions) {
      allQuestions.shuffle();
    }

    // Batasi jumlah pertanyaan jika diatur (dan bukan 0)
    if (topic.questionLimit > 0 && allQuestions.length > topic.questionLimit) {
      return allQuestions.sublist(0, topic.questionLimit);
    }

    return allQuestions;
  }

  Future<void> saveQuizSet(String topicName, QuizSet quizSet) async {
    final quizzesPath = await _quizPath;
    final fileName = '${quizSet.name.replaceAll(' ', '_').toLowerCase()}.json';
    final filePath = path.join(quizzesPath, topicName, fileName);
    final file = File(filePath);

    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(quizSet.toJson()));
  }

  // ==> FUNGSI BARU UNTUK MENGHAPUS FILE SET KUIS <==
  Future<void> deleteQuizSet(String topicName, String quizSetName) async {
    final quizzesPath = await _quizPath;
    final fileName = '${quizSetName.replaceAll(' ', '_').toLowerCase()}.json';
    final filePath = path.join(quizzesPath, topicName, fileName);
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<List<QuizTopic>> getAllTopics() async {
    final quizzesPath = await _quizPath;
    final directory = Directory(quizzesPath);
    if (!await directory.exists()) {
      return [];
    }

    final folderNames = directory
        .listSync()
        .whereType<Directory>()
        .map((item) => path.basename(item.path))
        .toList();

    List<QuizTopic> topics = [];
    for (var name in folderNames) {
      final config = await _getTopicConfig(name);
      topics.add(QuizTopic.fromConfig(name, config));
    }

    final positionedTopics = topics.where((t) => t.position != -1).toList();
    final unpositionedTopics = topics.where((t) => t.position == -1).toList();
    positionedTopics.sort((a, b) => a.position.compareTo(b.position));
    int maxPosition = positionedTopics.isNotEmpty
        ? positionedTopics
              .map((t) => t.position)
              .reduce((a, b) => a > b ? a : b)
        : -1;
    for (final topic in unpositionedTopics) {
      maxPosition++;
      topic.position = maxPosition;
      await _saveTopicConfig(topic);
    }
    final allTopics = [...positionedTopics, ...unpositionedTopics];
    allTopics.sort((a, b) => a.position.compareTo(b.position));
    bool needsResave = false;
    for (int i = 0; i < allTopics.length; i++) {
      if (allTopics[i].position != i) {
        allTopics[i].position = i;
        needsResave = true;
      }
    }
    if (needsResave) {
      await saveTopicsOrder(allTopics);
    }
    return allTopics;
  }

  Future<void> saveTopicsOrder(List<QuizTopic> topics) async {
    for (int i = 0; i < topics.length; i++) {
      final topic = topics[i];
      topic.position = i;
      await _saveTopicConfig(topic);
    }
  }

  Future<Map<String, dynamic>> _getTopicConfig(String topicName) async {
    final quizzesPath = await _quizPath;
    final configPath = path.join(quizzesPath, topicName, _configFile);
    final configFile = File(configPath);
    if (await configFile.exists()) {
      try {
        final jsonString = await configFile.readAsString();
        if (jsonString.isNotEmpty)
          return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        /* Abaikan */
      }
    }
    return {
      'icon': _defaultIcon,
      'position': -1,
      'shuffleQuestions': true,
      'questionLimit': 0,
      'includedQuizSets': [],
      'showCorrectAnswer': false,
      'autoAdvanceNextQuestion': false,
      'autoAdvanceDelay': 2,
    };
  }

  Future<void> saveTopic(QuizTopic topic) async {
    final quizzesPath = await _quizPath;
    final configPath = path.join(quizzesPath, topic.name, _configFile);
    final configFile = File(configPath);
    try {
      if (!await configFile.parent.exists()) {
        await configFile.parent.create(recursive: true);
      }
      const encoder = JsonEncoder.withIndent('  ');
      await configFile.writeAsString(encoder.convert(topic.toConfigJson()));
    } catch (e) {
      // Abaikan jika gagal menulis file
    }
  }

  Future<void> _saveTopicConfig(QuizTopic topic) async {
    await saveTopic(topic);
  }

  Future<void> addTopic(String topicName) async {
    if (topicName.isEmpty)
      throw Exception('Nama topik kuis tidak boleh kosong.');
    final quizzesPath = await _quizPath;
    final newTopicPath = path.join(quizzesPath, topicName);
    final directory = Directory(newTopicPath);
    if (await directory.exists()) {
      throw Exception('Topik kuis dengan nama "$topicName" sudah ada.');
    }
    try {
      await directory.create();
      final currentTopics = await getAllTopics();
      final newTopic = QuizTopic(
        name: topicName,
        position: currentTopics.length,
      );
      await _saveTopicConfig(newTopic);
    } catch (e) {
      throw Exception('Gagal membuat topik kuis: $e');
    }
  }

  Future<void> renameTopic(QuizTopic oldTopic, String newName) async {
    if (newName.isEmpty) throw Exception('Nama baru tidak boleh kosong.');
    final quizzesPath = await _quizPath;
    final oldPath = path.join(quizzesPath, oldTopic.name);
    final newPath = path.join(quizzesPath, newName);

    final oldDir = Directory(oldPath);
    if (!await oldDir.exists()) {
      throw Exception('Topik kuis yang ingin diubah tidak ditemukan.');
    }
    if (await Directory(newPath).exists()) {
      throw Exception('Topik kuis dengan nama "$newName" sudah ada.');
    }
    try {
      final fullTopicData = await getTopic(oldTopic.name);
      await oldDir.rename(newPath);

      final newTopicData = QuizTopic(
        name: newName,
        icon: fullTopicData.icon,
        position: fullTopicData.position,
        shuffleQuestions: fullTopicData.shuffleQuestions,
        questionLimit: fullTopicData.questionLimit,
        includedQuizSets: fullTopicData.includedQuizSets,
        showCorrectAnswer: fullTopicData.showCorrectAnswer,
        autoAdvanceNextQuestion: fullTopicData.autoAdvanceNextQuestion,
        autoAdvanceDelay: fullTopicData.autoAdvanceDelay,
      );
      await saveTopic(newTopicData);
    } catch (e) {
      throw Exception('Gagal mengubah nama topik kuis: $e');
    }
  }

  Future<void> deleteTopic(QuizTopic topic) async {
    final quizzesPath = await _quizPath;
    final topicPath = path.join(quizzesPath, topic.name);
    final directory = Directory(topicPath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    final remainingTopics = await getAllTopics();
    await saveTopicsOrder(remainingTopics);
  }
}
