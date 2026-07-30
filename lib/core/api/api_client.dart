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

    if (e.type == DioExceptionType.sendTimeout) {
      return ApiException(message: 'Gagal mengirim data ke server. Periksa jaringan Anda.');
    }

    if (e.type == DioExceptionType.connectionError) {
      final msg = e.message?.toLowerCase() ?? '';

      // 'Connection refused' = port tertutup, server tidak berjalan sama sekali
      if (msg.contains('refused')) {
        return ApiException(
          message: 'Tidak dapat terhubung ke server. Server SIEDA tidak berjalan.',
          statusCode: 0,
        );
      }

      // 'Connection reset / closed / lost' = koneksi diterima lalu diputus,
      // artinya server hidup tapi PHP/MySQL crash.
      if (msg.contains('reset') || msg.contains('closed') || msg.contains('lost')) {
        return ApiException(
          message: 'Server SIEDA tidak dapat memproses permintaan. '
              'Kemungkinan MySQL atau PHP-FPM bermasalah. '
              'Hubungi admin untuk mengecek server.',
          statusCode: 0,
        );
      }

      // Server benar-benar tidak bisa dijangkau (unknown reason)
      return ApiException(
        message: 'Tidak dapat terhubung ke server ${ApiEndpoints.baseUrl}. '
            'Pastikan server SIEDA sedang berjalan.',
        statusCode: 0,
      );
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
