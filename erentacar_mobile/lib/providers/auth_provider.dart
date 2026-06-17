import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoggedIn = false;
  bool _isLoading = true;
  String? _role;
  String? _fullName;
  String? _email;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get role => _role;
  String? get fullName => _fullName;
  String? get email => _email;

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await _authService.isLoggedIn();
      if (_isLoggedIn) {
        final user = await _authService.getCurrentUser();
        _role = user['role'] as String?;
        _fullName = user['fullName'] as String?;
        _email = user['email'] as String?;
      }
    } catch (_) {
      await _authService.logout();
      _isLoggedIn = false;
      _role = null;
      _fullName = null;
      _email = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final response = await _authService.login(email, password);
    _isLoggedIn = true;
    _role = response['role'];
    _fullName = response['fullName'];
    _email = response['email'];
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    _role = null;
    _fullName = null;
    _email = null;
    notifyListeners();
  }
}