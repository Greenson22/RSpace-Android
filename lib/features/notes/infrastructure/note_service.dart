// lib/features/notes/infrastructure/note_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/features/notes/domain/models/note_model.dart';
import 'package:my_aplication/features/notes/domain/models/note_topic_model.dart';
import 'package:path/path.dart' as path;

class NoteService {
  final PathService _pathService = PathService();
  static const String _configFileName = 'topic_config.json';

  Future<Directory> _getNotesBaseDir() async {
    final notesPath = await _pathService.notesPath;
    final dir = Directory(notesPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // ==> FUNGSI INI DIPERBARUI TOTAL UNTUK MENGELOLA POSISI <==
  Future<List<NoteTopic>> getTopics() async {
    final baseDir = await _getNotesBaseDir();
    final topicDirs = baseDir.listSync().whereType<Directory>();

    List<NoteTopic> topics = [];
    for (final dir in topicDirs) {
      final configFile = File(path.join(dir.path, _configFileName));
      if (await configFile.exists()) {
        final jsonString = await configFile.readAsString();
        topics.add(NoteTopic.fromJson(jsonDecode(jsonString)));
      } else {
        final topicName = path.basename(dir.path);
        final newTopic = NoteTopic(name: topicName);
        await saveTopic(newTopic); // Buat file config jika belum ada
        topics.add(newTopic);
      }
    }

    // Logika untuk memperbaiki dan mengurutkan posisi
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
      await saveTopic(topic);
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

  // ==> FUNGSI BARU UNTUK MENYIMPAN URUTAN <==
  Future<void> saveTopicsOrder(List<NoteTopic> topics) async {
    for (int i = 0; i < topics.length; i++) {
      final topic = topics[i];
      topic.position = i;
      await saveTopic(topic);
    }
  }

  Future<void> saveTopic(NoteTopic topic) async {
    final baseDir = await _getNotesBaseDir();
    final topicDir = Directory(path.join(baseDir.path, topic.name));
    final configFile = File(path.join(topicDir.path, _configFileName));
    await configFile.writeAsString(jsonEncode(topic.toJson()));
  }

  Future<void> createTopic(String name) async {
    final baseDir = await _getNotesBaseDir();
    final newDir = Directory(path.join(baseDir.path, name));
    if (await newDir.exists()) {
      throw Exception('Topik dengan nama "$name" sudah ada.');
    }
    await newDir.create();
    final topics = await getTopics();
    await saveTopic(NoteTopic(name: name, position: topics.length));
  }

  Future<void> renameTopic(String oldName, String newName) async {
    final baseDir = await _getNotesBaseDir();
    final oldDir = Directory(path.join(baseDir.path, oldName));
    final newDir = Directory(path.join(baseDir.path, newName));

    if (!await oldDir.exists()) {
      throw Exception('Topik "$oldName" tidak ditemukan.');
    }
    if (await newDir.exists()) {
      throw Exception('Topik dengan nama "$newName" sudah ada.');
    }

    final oldConfigFile = File(path.join(oldDir.path, _configFileName));
    NoteTopic oldTopic = NoteTopic(name: oldName);
    if (await oldConfigFile.exists()) {
      oldTopic = NoteTopic.fromJson(
        jsonDecode(await oldConfigFile.readAsString()),
      );
    }

    await oldDir.rename(newDir.path);
    await saveTopic(
      NoteTopic(
        name: newName,
        icon: oldTopic.icon,
        position: oldTopic.position,
      ),
    );
  }

  Future<void> deleteTopic(String name) async {
    final baseDir = await _getNotesBaseDir();
    final dirToDelete = Directory(path.join(baseDir.path, name));
    if (await dirToDelete.exists()) {
      await dirToDelete.delete(recursive: true);
    }
  }

  Future<List<Note>> getNotes(String topicName) async {
    final baseDir = await _getNotesBaseDir();
    final topicDir = Directory(path.join(baseDir.path, topicName));
    if (!await topicDir.exists()) return [];

    final files = topicDir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.json') && !f.path.endsWith(_configFileName),
    );

    final List<Note> notes = [];
    for (final file in files) {
      final jsonString = await file.readAsString();
      notes.add(Note.fromJson(jsonDecode(jsonString)));
    }
    return notes;
  }

  Future<void> saveNote(String topicName, Note note) async {
    final baseDir = await _getNotesBaseDir();
    final topicDir = Directory(path.join(baseDir.path, topicName));
    final file = File(path.join(topicDir.path, '${note.id}.json'));
    await file.writeAsString(jsonEncode(note.toJson()));
  }

  Future<void> deleteNote(String topicName, String noteId) async {
    final baseDir = await _getNotesBaseDir();
    final topicDir = Directory(path.join(baseDir.path, topicName));
    final file = File(path.join(topicDir.path, '$noteId.json'));
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> moveNote(Note note, String fromTopic, String toTopic) async {
    final baseDir = await _getNotesBaseDir();
    final fromDir = Directory(path.join(baseDir.path, fromTopic));
    final toDir = Directory(path.join(baseDir.path, toTopic));

    if (!await toDir.exists()) {
      await toDir.create();
    }

    final sourceFile = File(path.join(fromDir.path, '${note.id}.json'));
    final destinationFile = File(path.join(toDir.path, '${note.id}.json'));

    if (await sourceFile.exists()) {
      await sourceFile.rename(destinationFile.path);
    }
  }
}
