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

  // Add reorder, edit, delete methods here
}
