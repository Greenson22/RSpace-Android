// lib/features/admin/application/admin_provider.dart
import 'package:flutter/material.dart';
import '../domain/models/admin_user_model.dart';
import 'admin_service.dart';

class AdminProvider with ChangeNotifier {
  final AdminService _adminService = AdminService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  List<AdminUser> _users = [];
  List<AdminUser> get users => _users;

  AdminProvider() {
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _users = await _adminService.getAllUsers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> changePassword(int userId, String newPassword) async {
    try {
      return await _adminService.updateUserPassword(userId, newPassword);
    } catch (e) {
      rethrow;
    }
  }
}
