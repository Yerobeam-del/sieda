import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

class ApiClient {
  late final Dio _dio;
  static const String _tokenKey = 'Authorization';

  ApiClient({String? baseUrl, String? token}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    if (token != null && token.isNotEmpty) {
      _setToken(token);
    }

    _dio.interceptors.add(LogInterceptor(
      requestBody: kDebugMode,
      responseBody: kDebugMode,
      error: kDebugMode,
      logPrint: (obj) => debugPrint('[API] $obj'),
    ));
  }

  void _setToken(String token) {
    _dio.options.headers[_tokenKey] = 'Bearer $token';
  }

  Future<Map<String, dynamic>> _handleResponse(Response response) async {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data['success'] == true) {
        return data;
      }
      throw ApiException(
        message: data['message'] ?? 'Unknown error',
        statusCode: response.statusCode,
        errors: data['errors'] as Map<String, dynamic>?,
      );
    }
    return {'data': data};
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  ApiException _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException(message: 'Koneksi timeout. Periksa jaringan Anda.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return ApiException(message: 'Tidak dapat terhubung ke server.');
    }

    final response = e.response;
    if (response != null && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      return ApiException(
        message: data['message'] ?? 'Terjadi kesalahan',
        statusCode: response.statusCode,
        errors: data['errors'] as Map<String, dynamic>?,
      );
    }

    return ApiException(
      message: e.message ?? 'Terjadi kesalahan yang tidak diketahui',
      statusCode: response?.statusCode,
    );
  }
}
