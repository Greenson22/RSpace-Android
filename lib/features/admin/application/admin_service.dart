// lib/features/admin/application/admin_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_aplication/features/auth/application/auth_service.dart';
import '../domain/models/admin_user_model.dart';

class AdminService {
  final AuthService _authService = AuthService();

  Future<List<AdminUser>> getAllUsers() async {
    final domain = await _authService.getApiDomain();
    final token = await _authService.getToken();
    final response = await http.get(
      Uri.parse('$domain/api/admin/users'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => AdminUser.fromJson(item)).toList();
    } else {
      throw Exception('Gagal memuat daftar pengguna.');
    }
  }

  Future<String> updateUserPassword(int userId, String newPassword) async {
    final domain = await _authService.getApiDomain();
    final token = await _authService.getToken();
    final response = await http.put(
      Uri.parse('$domain/api/admin/users/$userId/password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'newPassword': newPassword}),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data['message'] ?? 'Password berhasil diperbarui.';
    } else {
      final errorMsg =
          data['errors']?[0]?['msg'] ??
          data['message'] ??
          'Gagal memperbarui password.';
      throw Exception(errorMsg);
    }
  }

  // ==> FUNGSI BARU UNTUK VERIFIKASI MANUAL <==
  Future<String> manuallyVerifyUser(int userId) async {
    final domain = await _authService.getApiDomain();
    final token = await _authService.getToken();
    final response = await http.put(
      Uri.parse('$domain/api/admin/users/$userId/verify'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = json.decode(response.body);
    if (response.statusCode == 200) {
      return data['message'] ?? 'Verifikasi berhasil.';
    } else {
      throw Exception(data['message'] ?? 'Gagal memverifikasi pengguna.');
    }
  }
}
