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

  // FITUR UPDATE PROMPT
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

  // --- FITUR BARU: DELETE PROMPT ---
  Future<void> deletePrompt(String category, PromptConcept prompt) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Hapus file dari penyimpanan
      await _promptService.deletePrompt(category, prompt.fileName);

      // Refresh daftar prompt di kategori yang sedang dipilih
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
    _isLoading = true;
    notifyListeners();
    _prompts = await _promptService.getPromptsInCategory(category);
    _isLoading = false;
    notifyListeners();
  }

  void clearCategorySelection() {
    _selectedCategory = null;
    _prompts = [];
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
