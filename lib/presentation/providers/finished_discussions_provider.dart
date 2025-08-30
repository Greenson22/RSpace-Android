// lib/presentation/providers/finished_discussions_provider.dart

import 'package:flutter/material.dart';
import '../../data/models/finished_discussion_model.dart';
import '../../data/services/discussion_service.dart';
import '../../data/services/finished_discussion_service.dart';

class FinishedDiscussionsProvider with ChangeNotifier {
  final FinishedDiscussionService _service = FinishedDiscussionService();
  final DiscussionService _discussionService = DiscussionService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<FinishedDiscussion> _finishedDiscussions = [];
  List<FinishedDiscussion> get finishedDiscussions => _finishedDiscussions;

  final Set<FinishedDiscussion> _selectedDiscussions = {};
  Set<FinishedDiscussion> get selectedDiscussions => _selectedDiscussions;
  bool get isSelectionMode => _selectedDiscussions.isNotEmpty;

  FinishedDiscussionsProvider() {
    fetchFinishedDiscussions();
  }

  Future<void> fetchFinishedDiscussions() async {
    _isLoading = true;
    notifyListeners();
    try {
      _finishedDiscussions = await _service.getAllFinishedDiscussions();
      _finishedDiscussions.sort(
        (a, b) => (b.discussion.finish_date ?? '').compareTo(
          a.discussion.finish_date ?? '',
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleSelection(FinishedDiscussion discussion) {
    if (_selectedDiscussions.contains(discussion)) {
      _selectedDiscussions.remove(discussion);
    } else {
      _selectedDiscussions.add(discussion);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedDiscussions.addAll(_finishedDiscussions);
    notifyListeners();
  }

  void clearSelection() {
    _selectedDiscussions.clear();
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    // ====================== AWAL PERUBAHAN ======================
    // Langkah 1: Hapus file HTML fisik yang tertaut terlebih dahulu
    for (final selected in _selectedDiscussions) {
      // Cek apakah ada file path yang tertaut
      if (selected.discussion.filePath != null &&
          selected.discussion.filePath!.isNotEmpty) {
        try {
          // Panggil service untuk menghapus file fisiknya
          await _discussionService.deleteLinkedFile(
            selected.discussion.filePath,
          );
        } catch (e) {
          // Jika gagal, tampilkan pesan error dan hentikan proses
          debugPrint("Gagal menghapus file HTML tertaut: ${e.toString()}");
          // Anda bisa melempar error di sini agar UI bisa menampilkannya
          throw Exception(
            'Gagal menghapus file: ${selected.discussion.filePath}. Proses dibatalkan.',
          );
        }
      }
    }
    // ======================= AKHIR PERUBAHAN =======================

    // Langkah 2: Kelompokkan diskusi untuk dihapus dari file JSON
    final Map<String, List<String>> discussionsToDeleteByFile = {};

    for (final selected in _selectedDiscussions) {
      final path = selected.subjectJsonPath;
      final discussionName = selected.discussion.discussion;
      if (discussionsToDeleteByFile.containsKey(path)) {
        discussionsToDeleteByFile[path]!.add(discussionName);
      } else {
        discussionsToDeleteByFile[path] = [discussionName];
      }
    }

    // Langkah 3: Panggil service untuk menghapus data diskusi dari setiap file JSON
    for (final entry in discussionsToDeleteByFile.entries) {
      await _discussionService.deleteMultipleDiscussions(
        entry.key,
        entry.value,
      );
    }

    // Langkah 4: Hapus dari state lokal dan perbarui UI
    _finishedDiscussions.removeWhere((d) => _selectedDiscussions.contains(d));
    _selectedDiscussions.clear();
    notifyListeners();
  }
}
