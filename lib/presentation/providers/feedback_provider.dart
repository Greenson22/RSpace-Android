// lib/presentation/providers/feedback_provider.dart
import 'package:flutter/material.dart';
import '../../data/models/feedback_model.dart';
import '../../data/services/feedback_service.dart';

class FeedbackProvider with ChangeNotifier {
  final FeedbackService _feedbackService = FeedbackService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<FeedbackItem> _allItems = [];
  List<FeedbackItem> _filteredItems = [];
  List<FeedbackItem> get filteredItems => _filteredItems;

  FeedbackType? _filterType;
  FeedbackType? get filterType => _filterType;

  FeedbackProvider() {
    fetchItems();
  }

  Future<void> fetchItems() async {
    _isLoading = true;
    notifyListeners();
    _allItems = await _feedbackService.loadFeedbackItems();
    _applyFilters();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveItems() async {
    await _feedbackService.saveFeedbackItems(_allItems);
    _applyFilters();
  }

  void setFilter(FeedbackType? type) {
    _filterType = type;
    _applyFilters();
  }

  void _applyFilters() {
    if (_filterType == null) {
      _filteredItems = List.from(_allItems);
    } else {
      _filteredItems = _allItems
          .where((item) => item.type == _filterType)
          .toList();
    }
    // Urutkan berdasarkan tanggal terbaru
    _filteredItems.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
  }

  Future<void> addItem(
    String title,
    String description,
    FeedbackType type,
  ) async {
    final newItem = FeedbackItem(
      title: title,
      description: description,
      type: type,
    );
    _allItems.add(newItem);
    await _saveItems();
  }

  Future<void> updateItem(FeedbackItem itemToUpdate) async {
    final index = _allItems.indexWhere((item) => item.id == itemToUpdate.id);
    if (index != -1) {
      itemToUpdate.updatedAt = DateTime.now();
      _allItems[index] = itemToUpdate;
      await _saveItems();
    }
  }

  Future<void> deleteItem(String id) async {
    _allItems.removeWhere((item) => item.id == id);
    await _saveItems();
  }

  Future<void> updateStatus(FeedbackItem item, FeedbackStatus newStatus) async {
    item.status = newStatus;
    item.updatedAt = DateTime.now();
    await updateItem(item);
  }
}
