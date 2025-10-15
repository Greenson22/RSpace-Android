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

  // ==> STATE BARU UNTUK PENGURUTAN <==
  String _sortType = 'modifiedAt'; // Default: urutkan berdasarkan tanggal
  String get sortType => _sortType;
  bool _sortAscending = false; // Default: terlama (false for descending/newest)
  bool get sortAscending => _sortAscending;
  String _searchQuery = '';

  NoteListProvider(this.topicName) {
    fetchNotes();
  }

  Future<void> fetchNotes() async {
    _isLoading = true;
    notifyListeners();
    _allNotes = await _noteService.getNotes(topicName);
    _applyFiltersAndSort(); // Terapkan pengurutan awal
    _isLoading = false;
    notifyListeners();
  }

  // ==> FUNGSI BARU UNTUK MENERAPKAN PENGURUTAN <==
  void applySort(String sortType, bool sortAscending) {
    _sortType = sortType;
    _sortAscending = sortAscending;
    _applyFiltersAndSort();
  }

  void search(String query) {
    _searchQuery = query.toLowerCase();
    _applyFiltersAndSort();
  }

  // ==> FUNGSI TERPUSAT UNTUK FILTER & SORT <==
  void _applyFiltersAndSort() {
    if (_searchQuery.isEmpty) {
      _filteredNotes = List.from(_allNotes);
    } else {
      _filteredNotes = _allNotes.where((note) {
        return note.title.toLowerCase().contains(_searchQuery) ||
            note.content.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Terapkan logika pengurutan
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
      // Untuk tanggal, ascending = true berarti terlama ke terbaru
      // Untuk judul, ascending = true berarti A ke Z
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

  Future<void> deleteNote(String noteId) async {
    await _noteService.deleteNote(topicName, noteId);
    await fetchNotes();
  }
}
