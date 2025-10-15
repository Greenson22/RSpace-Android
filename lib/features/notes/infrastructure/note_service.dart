// lib/features/notes/infrastructure/note_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:my_aplication/core/services/path_service.dart';
import 'package:my_aplication/features/notes/domain/models/note_model.dart';
import 'package:path/path.dart' as path;

class NoteService {
  final PathService _pathService = PathService();

  Future<Directory> _getNotesBaseDir() async {
    final notesPath = await _pathService.notesPath;
    final dir = Directory(notesPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<List<String>> getTopics() async {
    final baseDir = await _getNotesBaseDir();
    return baseDir
        .listSync()
        .whereType<Directory>()
        .map((dir) => path.basename(dir.path))
        .toList()
      ..sort();
  }

  Future<void> createTopic(String name) async {
    final baseDir = await _getNotesBaseDir();
    final newDir = Directory(path.join(baseDir.path, name));
    if (await newDir.exists()) {
      throw Exception('Topik dengan nama "$name" sudah ada.');
    }
    await newDir.create();
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
      (f) => f.path.endsWith('.json'),
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
