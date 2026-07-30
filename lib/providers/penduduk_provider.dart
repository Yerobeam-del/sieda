import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exception.dart';
import '../core/storage/local_storage.dart';
import '../models/penduduk_model.dart';

class PendudukProvider extends ChangeNotifier {
  List<PendudukModel> _pendudukList = [];
  PendudukModel? _selectedPenduduk;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  ApiException? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  String _searchQuery = '';

  List<PendudukModel> get pendudukList => _pendudukList;
  PendudukModel? get selectedPenduduk => _selectedPenduduk;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  ApiException? get error => _error;
  int get total => _total;
  String get searchQuery => _searchQuery;
  bool get hasMore => _currentPage < _lastPage;

  Future<void> loadPenduduk({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _pendudukList = [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'per_page': 25,
      };
      if (_searchQuery.isNotEmpty) queryParams['search'] = _searchQuery;

      final response = await client.get(ApiEndpoints.penduduk, queryParameters: queryParams);
      final data = response['data'] as List<dynamic>;
      final meta = response['meta'] as Map<String, dynamic>?;

      if (refresh) {
        _pendudukList = data.map((e) => PendudukModel.fromJson(e)).toList();
      } else {
        _pendudukList.addAll(data.map((e) => PendudukModel.fromJson(e)));
      }

      if (meta != null) {
        _currentPage = meta['current_page'] ?? 1;
        _lastPage = meta['last_page'] ?? 1;
        _total = meta['total'] ?? 0;
      }
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat data penduduk.');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;

    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'per_page': 25,
      };
      if (_searchQuery.isNotEmpty) queryParams['search'] = _searchQuery;

      final response = await client.get(ApiEndpoints.penduduk, queryParameters: queryParams);
      final data = response['data'] as List<dynamic>;
      final meta = response['meta'] as Map<String, dynamic>?;

      _pendudukList.addAll(data.map((e) => PendudukModel.fromJson(e)));
      if (meta != null) {
        _currentPage = meta['current_page'] ?? _currentPage;
        _lastPage = meta['last_page'] ?? _lastPage;
        _total = meta['total'] ?? _total;
      }
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat data tambahan.');
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> loadDetail(String nik) async {
    _isLoading = true;
    _error = null;
    _selectedPenduduk = null; // Clear previous selection
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final response = await client.get(ApiEndpoints.pendudukDetail(nik));
      _selectedPenduduk = PendudukModel.fromJson(response['data']);
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat detail penduduk.');
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    loadPenduduk(refresh: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
