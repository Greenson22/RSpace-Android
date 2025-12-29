// lib/features/prompt_library/application/prompt_provider.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/prompt_concept_model.dart';
import '../infrastructure/prompt_library_service.dart';

// Enum untuk tipe pengurutan
enum PromptSortType {
  titleAsc, // A-Z
  titleDesc, // Z-A
}

class PromptProvider with ChangeNotifier {
  final PromptLibraryService _promptService = PromptLibraryService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<String> _categories = [];
  List<String> get categories => _categories;

  List<PromptConcept> _prompts = [];
  List<PromptConcept> get prompts => _prompts;

  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  // State untuk pencarian
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  // State untuk pengurutan
  PromptSortType _sortType = PromptSortType.titleAsc;
  PromptSortType get sortType => _sortType;

  // Getter untuk list prompt yang sudah difilter DAN diurutkan
  List<PromptConcept> get filteredPrompts {
    // 1. Filter berdasarkan search query
    List<PromptConcept> result;
    if (_searchQuery.isEmpty) {
      result = List.from(_prompts); // Buat salinan list agar aman saat di-sort
    } else {
      final query = _searchQuery.toLowerCase();
      result = _prompts.where((prompt) {
        final title = prompt.title.toLowerCase();
        final desc = prompt.description.toLowerCase();
        return title.contains(query) || desc.contains(query);
      }).toList();
    }

    // 2. Urutkan hasil filter
    switch (_sortType) {
      case PromptSortType.titleAsc:
        result.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case PromptSortType.titleDesc:
        result.sort(
          (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
        );
        break;
    }

    return result;
  }

  PromptProvider() {
    loadCategories();
  }

  Future<void> loadCategories() async {
    _isLoading = true;
    notifyListeners();
    _categories = await _promptService.getCategories();
    _isLoading = false;
    notifyListeners();
  }

  // Method untuk mengubah query pencarian
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Method untuk mengubah tipe pengurutan
  void setSortType(PromptSortType type) {
    _sortType = type;
    notifyListeners();
  }

  Future<void> addCategory(String categoryName) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _promptService.createCategory(categoryName);
      await loadCategories();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPrompt(String category, PromptConcept prompt) async {
    _isLoading = true;
    notifyListeners();
    try {
      final fileName = _generateFileName(prompt.title);
      await _promptService.savePromptConcept(category, fileName, prompt);
      await selectCategory(category);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updatePrompt(
    String category,
    PromptConcept oldPrompt,
    PromptConcept newPrompt,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final oldFileName = oldPrompt.fileName;
      final newFileName = _generateFileName(newPrompt.title);

      // Jika nama file berubah (judul berubah), hapus file lama
      if (oldFileName != newFileName) {
        try {
          await _promptService.deletePrompt(category, oldFileName);
        } catch (e) {
          debugPrint("Gagal menghapus file lama: $e");
        }
      }

      await _promptService.savePromptConcept(category, newFileName, newPrompt);
      await selectCategory(category);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deletePrompt(String category, PromptConcept prompt) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _promptService.deletePrompt(category, prompt.fileName);
      await selectCategory(category);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- FITUR: Duplicate ---
  Future<void> duplicatePrompt(String category, PromptConcept prompt) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newTitle = '${prompt.title} (Copy)';
      final newId =
          '${category.toUpperCase()}-${const Uuid().v4().substring(0, 4)}';

      final newPrompt = PromptConcept(
        idPrompt: newId,
        title: newTitle,
        description: prompt.description,
        content: prompt.content,
        fileName: '', // Akan di-generate
      );

      final fileName = _generateFileName(newTitle);
      await _promptService.savePromptConcept(category, fileName, newPrompt);
      await selectCategory(category);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- FITUR: Move ---
  Future<void> movePrompt(
    String currentCategory,
    String targetCategory,
    PromptConcept prompt,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Simpan di kategori baru
      final newId =
          '${targetCategory.toUpperCase()}-${const Uuid().v4().substring(0, 4)}';
      final fileName = _generateFileName(prompt.title);

      final movedPrompt = PromptConcept(
        idPrompt: newId,
        title: prompt.title,
        content: prompt.content,
        description: prompt.description,
        fileName: fileName,
      );

      await _promptService.savePromptConcept(
        targetCategory,
        fileName,
        movedPrompt,
      );

      // 2. Hapus dari kategori lama
      await _promptService.deletePrompt(currentCategory, prompt.fileName);

      // 3. Refresh kategori saat ini
      await selectCategory(currentCategory);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- FITUR: Copy ---
  Future<void> copyPromptToCategory(
    String targetCategory,
    PromptConcept prompt,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      final newId =
          '${targetCategory.toUpperCase()}-${const Uuid().v4().substring(0, 4)}';
      final fileName = _generateFileName(prompt.title);

      final copiedPrompt = PromptConcept(
        idPrompt: newId,
        title: prompt.title,
        content: prompt.content,
        description: prompt.description,
        fileName: fileName,
      );

      await _promptService.savePromptConcept(
        targetCategory,
        fileName,
        copiedPrompt,
      );
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectCategory(String category) async {
    _selectedCategory = category;
    _searchQuery = ''; // Reset pencarian saat ganti kategori
    _isLoading = true;
    notifyListeners();
    _prompts = await _promptService.getPromptsInCategory(category);
    _isLoading = false;
    notifyListeners();
  }

  void clearCategorySelection() {
    _selectedCategory = null;
    _prompts = [];
    _searchQuery = ''; // Reset pencarian saat kembali ke menu utama
    notifyListeners();
  }

  String _generateFileName(String title) {
    final safeTitle = title
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
    return '$safeTitle.json';
  }
}
