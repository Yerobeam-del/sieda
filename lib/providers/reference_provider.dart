import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exception.dart';
import '../core/storage/local_storage.dart';
import '../database/local_database.dart';
import '../models/reference_model.dart';

class ReferenceProvider extends ChangeNotifier {
  ReferenceData? _data;
  bool _isLoading = false;
  ApiException? _error;

  ReferenceData? get data => _data;
  bool get isLoading => _isLoading;
  ApiException? get error => _error;

  /// Load all reference data from API, fallback to cache if offline.
  Future<void> loadReferences({bool forceRefresh = false}) async {
    if (_data != null && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      if (token == null) return;

      final client = ApiClient(token: token);
      final response = await client.get(ApiEndpoints.referencesAll);
      final dataJson = response['data'] as Map<String, dynamic>;

      _data = ReferenceData.fromJson(dataJson);

      // Cache references locally
      try {
        await LocalDatabase().cacheReferences(dataJson);
      } catch (_) {}
    } on ApiException catch (e) {
      _error = e;
      // Try loading from cache
      await _loadFromCache();
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat data referensi.');
      await _loadFromCache();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFromCache() async {
    try {
      final cached = await LocalDatabase().getCachedReferences();
      if (cached != null && cached['json_data'] != null) {
        final data = jsonDecode(cached['json_data'] as String) as Map<String, dynamic>;
        _data = ReferenceData.fromJson(data);
      }
    } catch (_) {}
  }

  /// Load kelompok dasawisma list for form dropdowns
  Future<List<KelompokDasawismaItem>> loadKelompokDasawisma() async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) return [];

      final client = ApiClient(token: token);
      final response = await client.get(ApiEndpoints.dasawismaKelompok);
      final data = response['data'] as List<dynamic>;
      return data.map((e) => KelompokDasawismaItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[Reference] Gagal load kelompok: $e');
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
