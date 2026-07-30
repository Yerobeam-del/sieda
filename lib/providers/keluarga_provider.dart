import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exception.dart';
import '../core/storage/local_storage.dart';
import '../models/keluarga_model.dart';

class KeluargaProvider extends ChangeNotifier {
  List<KeluargaModel> _keluargaList = [];
  KeluargaModel? _selectedKeluarga;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  ApiException? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  String _searchQuery = '';

  List<KeluargaModel> get keluargaList => _keluargaList;
  KeluargaModel? get selectedKeluarga => _selectedKeluarga;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  ApiException? get error => _error;
  int get total => _total;
  String get searchQuery => _searchQuery;
  bool get hasMore => _currentPage < _lastPage;

  Future<void> loadKeluarga({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _keluargaList = [];
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
      queryParams['with'] = 'kepala_keluarga,kelompok_dasawisma';

      final response = await client.get(ApiEndpoints.keluarga, queryParameters: queryParams);
      final data = response['data'] as List<dynamic>;
      final meta = response['meta'] as Map<String, dynamic>?;

      if (refresh) {
        _keluargaList = data.map((e) => KeluargaModel.fromJson(e)).toList();
      } else {
        _keluargaList.addAll(data.map((e) => KeluargaModel.fromJson(e)));
      }

      if (meta != null) {
        _currentPage = meta['current_page'] ?? 1;
        _lastPage = meta['last_page'] ?? 1;
        _total = meta['total'] ?? 0;
      }
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat data keluarga.');
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
      final response = await client.get(
        ApiEndpoints.keluarga,
        queryParameters: {
          'page': _currentPage,
          'per_page': 25,
          if (_searchQuery.isNotEmpty) 'search': _searchQuery,
        },
      );
      final data = response['data'] as List<dynamic>;
      final meta = response['meta'] as Map<String, dynamic>?;

      _keluargaList.addAll(data.map((e) => KeluargaModel.fromJson(e)));
      if (meta != null) {
        _currentPage = meta['current_page'] ?? _currentPage;
        _lastPage = meta['last_page'] ?? _lastPage;
        _total = meta['total'] ?? _total;
      }
    } catch (_) {}

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> loadDetail(String noKk) async {
    _isLoading = true;
    _error = null;
    _selectedKeluarga = null; // Clear previous selection
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final response = await client.get(ApiEndpoints.keluargaDetail(noKk));
      _selectedKeluarga = KeluargaModel.fromJson(response['data']);
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat detail keluarga.');
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    loadKeluarga(refresh: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
