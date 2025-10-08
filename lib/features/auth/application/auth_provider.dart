// lib/features/auth/application/auth_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../application/auth_service.dart';
import '../domain/user_model.dart';

enum AuthState { uninitialized, authenticated, unauthenticated }

enum LoginStatus { idle, loading, success, error }

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _authState = AuthState.uninitialized;
  User? _user;
  File? _localProfilePicture;
  bool _isProfilePictureLoading = false;

  LoginStatus _loginStatus = LoginStatus.idle;
  String _loginMessage = '';

  AuthState get authState => _authState;
  User? get user => _user;
  File? get localProfilePicture => _localProfilePicture;
  bool get isProfilePictureLoading => _isProfilePictureLoading;

  AuthService get authService => _authService;

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
        _isProfilePictureLoading = true;
        notifyListeners();
        if (_user != null) {
          _localProfilePicture = await _authService.getProfilePicture(_user!);
        }
      } catch (e) {
        _authState = AuthState.unauthenticated;
        _user = null;
        _localProfilePicture = null;
      } finally {
        _isProfilePictureLoading = false;
      }
    } else {
      _authState = AuthState.unauthenticated;
      _user = null;
      _localProfilePicture = null;
      _isProfilePictureLoading = false;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _loginStatus = LoginStatus.loading;
    _loginMessage = 'Mencoba login...';
    notifyListeners();

    try {
      await _authService.login(email, password);
      await checkLoginStatus();

      _loginStatus = LoginStatus.success;
      _loginMessage = 'Login Berhasil! Mengalihkan...';
      notifyListeners();

      await Future.delayed(const Duration(seconds: 1));
    } catch (e) {
      _loginStatus = LoginStatus.error;
      _loginMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

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
    _localProfilePicture = null;
    _authState = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<void> uploadProfilePicture(File imageFile) async {
    await _authService.uploadProfilePicture(imageFile);
    await checkLoginStatus();
  }

  Future<void> resendVerification(String email) async {
    try {
      final message = await _authService.resendVerificationEmail(email);
      _loginStatus = LoginStatus.success;
      _loginMessage = message;
      notifyListeners();
      await Future.delayed(const Duration(seconds: 5));
      resetLoginStatus();
    } catch (e) {
      _loginStatus = LoginStatus.error;
      _loginMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
}
