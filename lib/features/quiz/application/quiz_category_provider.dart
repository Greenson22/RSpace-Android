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
    _categories = await _quizService.getAllCategories();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    await _quizService.addCategory(name);
    await fetchCategories();
  }

  // ==> FUNGSI BARU UNTUK MENGUBAH IKON
  Future<void> editCategoryIcon(QuizCategory category, String newIcon) async {
    final categoryToUpdate = _categories.firstWhere(
      (c) => c.name == category.name,
    );
    categoryToUpdate.icon = newIcon;
    await _quizService.saveCategory(categoryToUpdate);
    notifyListeners();
  }

  // >> FUNGSI BARU UNTUK RENAME <<
  Future<void> editCategoryName(QuizCategory category, String newName) async {
    await _quizService.renameCategory(category, newName);
    await fetchCategories();
  }

  // >> FUNGSI BARU UNTUK DELETE <<
  Future<void> deleteCategory(QuizCategory category) async {
    await _quizService.deleteCategory(category);
    await fetchCategories();
  }
}
