import 'api_client.dart';

/// Helper untuk mengambil semua data dari endpoint yang memiliki pagination.
///
/// Backend SIEDA tidak lagi mendukung `per_page=all` — maksimal per halaman adalah 100.
/// Helper ini melakukan loop halaman sampai semua data terambil, dengan batas
/// keamanan max 50 iterasi (5000 record) untuk mencegah infinite loop.
Future<Map<String, dynamic>> fetchAllPages(
  ApiClient client,
  String path, {
  Map<String, dynamic>? queryParameters,
  int maxIterations = 50,
}) async {
  final allData = <dynamic>[];
  int? lastPage;
  var total = 0;

  for (var page = 1; page <= maxIterations; page++) {
    final params = <String, dynamic>{
      'page': page,
      'per_page': 100,
      ...?queryParameters,
    };

    final response = await client.get(path, queryParameters: params);
    final data = response['data'] as List<dynamic>;
    allData.addAll(data);

    // Pelajari last_page dari meta pagination di response pertama
    if (lastPage == null && response['meta'] is Map<String, dynamic>) {
      lastPage = (response['meta'] as Map<String, dynamic>)['last_page'] as int?;
      total = (response['meta'] as Map<String, dynamic>)['total'] as int? ?? data.length;
    }

    // Berhenti jika sudah sampai halaman terakhir atau halaman ini kosong
    if ((lastPage != null && page >= lastPage) || data.isEmpty) {
      break;
    }
  }

  // Kembalikan format yang kompatibel dengan respons paginated backend
  return {
    'data': allData,
    'meta': {
      'current_page': lastPage ?? 1,
      'last_page': lastPage ?? 1,
      'per_page': allData.length,
      'total': total,
    },
  };
}

/// Khusus untuk endpoint yang perlu memuat SEMUA data dalam satu kali panggilan
/// (miss: sinkronisasi offline, dropdown berjumlah besar).
/// Mengembalikan List langsung (bukan meta pagination).
Future<List<T>> fetchAllRecords<T>(
  ApiClient client,
  String path, {
  Map<String, dynamic>? queryParameters,
  T Function(dynamic)? fromJson,
}) async {
  final result = await fetchAllPages(client, path, queryParameters: queryParameters);
  final data = result['data'] as List<dynamic>;
  if (fromJson != null) {
    return data.map(fromJson).toList();
  }
  return data.cast<T>();
}
