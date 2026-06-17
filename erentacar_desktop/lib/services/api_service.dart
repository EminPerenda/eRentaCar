import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../config/app_router.dart';
import '../screens/auth/login_screen.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _storage.deleteAll();
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
        return handler.next(error);
      },
    ));
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final response = await _dio.get(path, queryParameters: params);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> post(String path, dynamic data) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> put(String path, dynamic data) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> uploadFile(String path, XFile file,
      {Map<String, dynamic>? data}) async {
    try {
      final formData = FormData.fromMap({
        ...?data,
        'file': await MultipartFile.fromFile(file.path,
            filename: file.name),
      });
      final response = await _dio.post(path, data: formData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.response?.statusCode == 401) {
      return 'Sesija je istekla. Molimo prijavite se ponovo.';
    }
    final responseData = e.response?.data;
    if (responseData is Map<String, dynamic> && responseData['message'] != null) {
      return responseData['message'].toString();
    }
    if (responseData is String && responseData.isNotEmpty) {
      return responseData;
    }
    final statusCode = e.response?.statusCode;
    if (statusCode != null) {
      return responseData != null
          ? 'HTTP $statusCode: $responseData'
          : 'HTTP $statusCode: ${e.message ?? 'Nepoznata greška'}';
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Timeout — provjeri internet konekciju.';
      case DioExceptionType.connectionError:
        return 'Nije moguće spojiti se na server.';
      default:
        return 'Došlo je do greške. Pokušaj ponovo.';
    }
  }
}
