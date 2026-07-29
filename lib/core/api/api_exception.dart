class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';

  String get friendlyMessage {
    if (statusCode == 401) return 'Email atau password salah.';
    if (statusCode == 403) return 'Anda tidak memiliki akses.';
    if (statusCode == 404) return 'Data tidak ditemukan.';
    if (statusCode == 422) {
      if (errors != null && errors!.isNotEmpty) {
        final firstError = errors!.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
      }
      return 'Data yang dimasukkan tidak valid.';
    }
    if (statusCode == 500) return 'Terjadi kesalahan server. Silakan coba lagi.';
    if (message.isEmpty) return 'Terjadi kesalahan. Periksa koneksi internet Anda.';
    return message;
  }
}
