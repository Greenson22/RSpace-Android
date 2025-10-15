// lib/features/notes/application/note_list_provider.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/notes/domain/models/note_model.dart';
import 'package:my_aplication/features/notes/infrastructure/note_service.dart';

class NoteListProvider with ChangeNotifier {
  final NoteService _noteService = NoteService();
  final String topicName;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Note> _allNotes = [];
  List<Note> _filteredNotes = [];
  List<Note> get notes => _filteredNotes;

  NoteListProvider(this.topicName) {
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    _isLoading = true;
    notifyListeners();
    _allNotes = await _noteService.getNotes(topicName);
    _filteredNotes = _allNotes;
    _isLoading = false;
    notifyListeners();
  }

  void search(String query) {
    if (query.isEmpty) {
      _filteredNotes = _allNotes;
    } else {
      final q = query.toLowerCase();
      _filteredNotes = _allNotes.where((note) {
        return note.title.toLowerCase().contains(q) ||
            note.content.toLowerCase().contains(q);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> deleteNote(String noteId) async {
    await _noteService.deleteNote(topicName, noteId);
    await fetchNotes();
  }
}
