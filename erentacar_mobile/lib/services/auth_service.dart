import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';
import '../config/api_config.dart';

class AuthService {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _api.post(ApiConfig.login, {
      'email': email,
      'password': password,
    });
    await _storage.write(key: 'token', value: response['token']);
    await _storage.write(key: 'role', value: response['role']);
    await _storage.write(key: 'fullName', value: response['fullName']);
    await _storage.write(key: 'email', value: response['email']);
    return response;
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiConfig.logout, {});
    } catch (_) {
      // Token may be expired; proceed with local cleanup regardless
    }
    await _storage.deleteAll();
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<String?> getRole() async {
    return await _storage.read(key: 'role');
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _api.get(ApiConfig.me);
    return Map<String, dynamic>.from(response as Map);
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null && token.isNotEmpty;
  }
}