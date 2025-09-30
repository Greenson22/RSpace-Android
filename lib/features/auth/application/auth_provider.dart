// lib/features/auth/application/auth_provider.dart

import 'package:flutter/material.dart';
import '../application/auth_service.dart';
import '../domain/user_model.dart';

// Enum untuk status autentikasi yang lebih deskriptif
enum AuthState { uninitialized, authenticated, unauthenticated, authenticating }

// Enum untuk status proses login di UI
enum LoginStatus { idle, loading, success, error }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _authState = AuthState.uninitialized;
  User? _user;
  // State baru untuk UI login
  LoginStatus _loginStatus = LoginStatus.idle;
  String _loginMessage = '';

  AuthState get authState => _authState;
  User? get user => _user;
  // Getter baru untuk UI
  LoginStatus get loginStatus => _loginStatus;
  String get loginMessage => _loginMessage;

  AuthProvider() {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final token = await _authService.getToken();
    if (token != null) {
      try {
        _user = await _authService.getUserProfile();
        _authState = AuthState.authenticated;
      } catch (e) {
        _authState = AuthState.unauthenticated;
      }
    } else {
      _authState = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    // 1. Set status ke 'loading' dan berikan pesan
    _loginStatus = LoginStatus.loading;
    _loginMessage = 'Mencoba login...';
    notifyListeners();

    try {
      await _authService.login(email, password);
      _user = await _authService.getUserProfile();
      _authState = AuthState.authenticated;

      // 2. Set status ke 'success' jika berhasil
      _loginStatus = LoginStatus.success;
      _loginMessage = 'Login Berhasil! Mengalihkan...';
      notifyListeners();

      // Beri sedikit jeda agar pesan sukses terlihat sebelum navigasi
      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      // 3. Set status ke 'error' jika gagal
      _loginStatus = LoginStatus.error;
      _loginMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  // Fungsi untuk mereset status login setelah selesai
  void resetLoginStatus() {
    _loginStatus = LoginStatus.idle;
    _loginMessage = '';
  }

  Future<void> register(String name, String email, String password) async {
    await _authService.register(name, email, password);
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _authState = AuthState.unauthenticated;
    notifyListeners();
  }
}
