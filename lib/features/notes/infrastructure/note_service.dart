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

  Future<List<NoteTopic>> getTopics() async {
    final baseDir = await _getNotesBaseDir();
    final topicDirs = baseDir.listSync().whereType<Directory>();

    final List<NoteTopic> topics = [];
    for (final dir in topicDirs) {
      final configFile = File(path.join(dir.path, _configFileName));
      if (await configFile.exists()) {
        final jsonString = await configFile.readAsString();
        topics.add(NoteTopic.fromJson(jsonDecode(jsonString)));
      } else {
        // Fallback for older folders without config
        topics.add(NoteTopic(name: path.basename(dir.path)));
      }
    }

    topics.sort((a, b) => a.name.compareTo(b.name));
    return topics;
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
    await saveTopic(NoteTopic(name: name));
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

    await oldDir.rename(newDir.path);
    await saveTopic(NoteTopic(name: newName, icon: '🗒️')); // Create new config
    final oldConfigFile = File(
      path.join(newDir.path, oldName, _configFileName),
    );
    if (await oldConfigFile.exists()) {
      await oldConfigFile.delete();
    }
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
    notes.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
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
}
