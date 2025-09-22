// lib/features/quiz/application/quiz_category_provider.dart
import 'package:flutter/material.dart';
import '../domain/models/quiz_model.dart';
import 'quiz_service.dart';

class QuizCategoryProvider with ChangeNotifier {
  final QuizService _quizService = QuizService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<QuizCategory> _categories = [];
  List<QuizCategory> get categories => _categories;

  QuizCategoryProvider() {
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();
    // Ambil kategori dasar terlebih dahulu
    _categories = await _quizService.getAllCategories();
    // ==> PERUBAHAN DI SINI: Muat topik untuk setiap kategori
    for (var category in _categories) {
      category.topics = await _quizService.getAllTopics(category.name);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> reorderCategories(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _categories.removeAt(oldIndex);
    _categories.insert(newIndex, item);
    await _quizService.saveCategoriesOrder(_categories);
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    await _quizService.addCategory(name);
    await fetchCategories();
  }

  Future<void> editCategoryIcon(QuizCategory category, String newIcon) async {
    final categoryToUpdate = _categories.firstWhere(
      (c) => c.name == category.name,
    );
    categoryToUpdate.icon = newIcon;
    await _quizService.saveCategory(categoryToUpdate);
    notifyListeners();
  }

  Future<void> editCategoryName(QuizCategory category, String newName) async {
    await _quizService.renameCategory(category, newName);
    await fetchCategories();
  }

  Future<void> deleteCategory(QuizCategory category) async {
    await _quizService.deleteCategory(category);
    await fetchCategories();
  }
}
