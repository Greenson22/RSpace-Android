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

  // ==> FUNGSI BARU UNTUK VERIFIKASI MANUAL <==
  Future<String> verifyUser(int userId) async {
    try {
      final message = await _adminService.manuallyVerifyUser(userId);
      // Perbarui state pengguna secara lokal setelah berhasil
      final userIndex = _users.indexWhere((user) => user.id == userId);
      if (userIndex != -1) {
        _users[userIndex] = AdminUser(
          id: _users[userIndex].id,
          name: _users[userIndex].name,
          email: _users[userIndex].email,
          createdAt: _users[userIndex].createdAt,
          isVerified: true, // Ubah status menjadi true
        );
        notifyListeners();
      }
      return message;
    } catch (e) {
      rethrow;
    }
  }
}
