// lib/features/auth/application/auth_provider.dart

import 'package:flutter/material.dart';
import '../application/auth_service.dart';
import '../domain/user_model.dart';

enum AuthState { uninitialized, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _authState = AuthState.uninitialized;
  User? _user;

  AuthState get authState => _authState;
  User? get user => _user;

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
    await _authService.login(email, password);
    await checkLoginStatus();
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
