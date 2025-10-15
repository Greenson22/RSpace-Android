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

  String _sortType = 'modifiedAt';
  String get sortType => _sortType;
  bool _sortAscending = false;
  bool get sortAscending => _sortAscending;
  String _searchQuery = '';

  NoteListProvider(this.topicName) {
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    _isLoading = true;
    notifyListeners();
    _allNotes = await _noteService.getNotes(topicName);
    _applyFiltersAndSort();
    _isLoading = false;
    notifyListeners();
  }

  void applySort(String sortType, bool sortAscending) {
    _sortType = sortType;
    _sortAscending = sortAscending;
    _applyFiltersAndSort();
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    if (_searchQuery.isEmpty) {
      _filteredNotes = List.from(_allNotes);
    } else {
      _filteredNotes = _allNotes.where((note) {
        return note.title.toLowerCase().contains(_searchQuery) ||
            note.content.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    _filteredNotes.sort((a, b) {
      int result;
      switch (_sortType) {
        case 'title':
          result = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case 'modifiedAt':
        default:
          result = a.modifiedAt.compareTo(b.modifiedAt);
          break;
      }
      return _sortAscending ? result : -result;
    });

    notifyListeners();
  }

  Future<void> renameNote(Note note, String newTitle) async {
    note.title = newTitle;
    note.modifiedAt = DateTime.now();
    await _noteService.saveNote(topicName, note);
    await fetchNotes();
  }

  // ==> FUNGSI BARU DITAMBAHKAN DI SINI <==
  Future<void> updateNoteIcon(Note note, String newIcon) async {
    note.icon = newIcon;
    note.modifiedAt = DateTime.now();
    await _noteService.saveNote(topicName, note);
    notifyListeners(); // Langsung update UI tanpa perlu fetch ulang
  }

  Future<void> deleteNote(String noteId) async {
    await _noteService.deleteNote(topicName, noteId);
    await fetchNotes();
  }
}
