// lib/features/prompt_library/application/prompt_provider.dart

import 'package:flutter/material.dart';
import '../domain/models/prompt_concept_model.dart';
import '../infrastructure/prompt_library_service.dart';

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

  // Getter untuk list prompt yang sudah difilter
  List<PromptConcept> get filteredPrompts {
    if (_searchQuery.isEmpty) {
      return _prompts;
    }
    return _prompts.where((prompt) {
      final query = _searchQuery.toLowerCase();
      final title = prompt.title.toLowerCase();
      final desc = prompt.description.toLowerCase();
      return title.contains(query) || desc.contains(query);
    }).toList();
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
