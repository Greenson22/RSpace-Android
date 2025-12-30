// lib/features/prompt_library/application/prompt_provider.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../domain/models/prompt_concept_model.dart';
import '../infrastructure/prompt_library_service.dart';

enum PromptSortType { titleAsc, titleDesc }

class PromptProvider with ChangeNotifier {
  final PromptLibraryService _promptService = PromptLibraryService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<String> _categories = [];
  List<String> get categories => _categories;

  // Map untuk menyimpan ikon kategori
  final Map<String, String> _categoryIcons = {};

  List<PromptConcept> _prompts = [];
  List<PromptConcept> get prompts => _prompts;

  String? _selectedCategory;
  String? get selectedCategory => _selectedCategory;

  // --- Search & Sort untuk Prompt (Item) ---
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  PromptSortType _sortType = PromptSortType.titleAsc;
  PromptSortType get sortType => _sortType;

  // --- Search & Sort untuk Kategori (Topic) [BARU] ---
  String _categorySearchQuery = '';
  String get categorySearchQuery => _categorySearchQuery;

  PromptSortType _categorySortType = PromptSortType.titleAsc;
  PromptSortType get categorySortType => _categorySortType;

  bool _showHidden = false;
  bool get showHidden => _showHidden;

  // Getter untuk ikon
  String? getCategoryIcon(String category) => _categoryIcons[category];

  // Getter untuk Categories yang sudah difilter dan diurutkan [BARU]
  List<String> get filteredCategories {
    List<String> result;

    // 1. Filter
    if (_categorySearchQuery.isEmpty) {
      result = List.from(_categories);
    } else {
      final query = _categorySearchQuery.toLowerCase();
      result = _categories.where((cat) {
        // Hapus prefix '.' jika ada untuk pencarian
        final displayName = cat.startsWith('.') ? cat.substring(1) : cat;
        return displayName.toLowerCase().contains(query);
      }).toList();
    }

    // 2. Sort
    result.sort((a, b) {
      // Bandingkan berdasarkan nama tampilan (tanpa titik hidden)
      final nameA = a.startsWith('.') ? a.substring(1) : a;
      final nameB = b.startsWith('.') ? b.substring(1) : b;

      final comparison = nameA.toLowerCase().compareTo(nameB.toLowerCase());

      return _categorySortType == PromptSortType.titleAsc
          ? comparison
          : -comparison;
    });

    return result;
  }

  List<PromptConcept> get filteredPrompts {
    List<PromptConcept> result;
    if (_searchQuery.isEmpty) {
      result = List.from(_prompts);
    } else {
      final query = _searchQuery.toLowerCase();
      result = _prompts.where((prompt) {
        final title = prompt.title.toLowerCase();
        final desc = prompt.description.toLowerCase();
        return title.contains(query) || desc.contains(query);
      }).toList();
    }

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

    _categories = await _promptService.getCategories(
      includeHidden: _showHidden,
    );

    // Load icons
    _categoryIcons.clear();
    for (final category in _categories) {
      final icon = await _promptService.getCategoryIcon(category);
      if (icon != null) {
        _categoryIcons[category] = icon;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  void toggleShowHidden() {
    _showHidden = !_showHidden;
    loadCategories();
  }

  // Setters untuk Prompt Search/Sort
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortType(PromptSortType type) {
    _sortType = type;
    notifyListeners();
  }

  // Setters untuk Category Search/Sort [BARU]
  void setCategorySearchQuery(String query) {
    _categorySearchQuery = query;
    notifyListeners();
  }

  void setCategorySortType(PromptSortType type) {
    _categorySortType = type;
    notifyListeners();
  }

  Future<void> updateCategoryIcon(String category, String icon) async {
    try {
      await _promptService.saveCategoryIcon(category, icon);
      _categoryIcons[category] = icon;
      notifyListeners();
    } catch (e) {
      debugPrint('Gagal update ikon: $e');
      rethrow;
    }
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

  Future<void> renameCategory(String oldName, String newName) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _promptService.renameCategory(oldName, newName);
      await loadCategories();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String categoryName) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _promptService.deleteCategory(categoryName);
      await loadCategories();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> hideCategory(String categoryName) async {
    if (categoryName.startsWith('.')) return;
    final newName = '.$categoryName';
    await renameCategory(categoryName, newName);
  }

  Future<void> unhideCategory(String categoryName) async {
    if (!categoryName.startsWith('.')) return;
    final newName = categoryName.substring(1);
    await renameCategory(categoryName, newName);
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
        fileName: '',
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

  Future<void> movePrompt(
    String currentCategory,
    String targetCategory,
    PromptConcept prompt,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
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

      await _promptService.deletePrompt(currentCategory, prompt.fileName);
      await selectCategory(currentCategory);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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
    _searchQuery = ''; // Reset prompt search
    _isLoading = true;
    notifyListeners();
    _prompts = await _promptService.getPromptsInCategory(category);
    _isLoading = false;
    notifyListeners();
  }

  void clearCategorySelection() {
    _selectedCategory = null;
    _prompts = [];
    _searchQuery = '';
    // Optional: Reset category search/sort when exiting folder?
    // _categorySearchQuery = '';
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
