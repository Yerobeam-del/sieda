import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exception.dart';
import '../core/storage/local_storage.dart';
import '../database/local_database.dart';
import '../models/catatan_model.dart';

class CatatanProvider extends ChangeNotifier {
  List<CatatanKelahiranKematianModel> _catatanList = [];
  CatatanKelahiranKematianModel? _selectedCatatan;
  bool _isLoading = false;
  ApiException? _error;
  String _filterStatus = 'all'; // all, hamil, melahirkan, nifas, meninggal

  List<CatatanKelahiranKematianModel> get catatanList => _catatanList;
  CatatanKelahiranKematianModel? get selectedCatatan => _selectedCatatan;
  bool get isLoading => _isLoading;
  ApiException? get error => _error;
  String get filterStatus => _filterStatus;

  List<CatatanKelahiranKematianModel> get filteredList {
    if (_filterStatus == 'all') return _catatanList;
    return _catatanList.where((c) {
      if (_filterStatus == 'death') return c.isDeath;
      return c.statusIbu?.toLowerCase() == _filterStatus;
    }).toList();
  }

  /// Load all catatan from API, fallback to cache
  Future<void> loadCatatan({bool refresh = false}) async {
    if (refresh) {
      _catatanList = [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        _error = ApiException(message: 'Silakan login terlebih dahulu.');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final client = ApiClient(token: token);
      final response = await client.get(ApiEndpoints.catatanKelahiranKematian);
      final data = response['data'] as List<dynamic>;

      _catatanList = data
          .map((e) => CatatanKelahiranKematianModel.fromJson(e as Map<String, dynamic>))
          .toList();

      // Cache locally
      try {
        await LocalDatabase().cacheCatatanList(
          data.cast<Map<String, dynamic>>(),
        );
      } catch (_) {}
    } on ApiException catch (e) {
      _error = e;
      await _loadFromCache();
    } catch (e) {
      debugPrint('[Catatan] Error loading list: $e');
      _error = ApiException(message: 'Gagal memuat catatan.');
      await _loadFromCache();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadFromCache() async {
    try {
      final cached = await LocalDatabase().getCachedCatatan();
      if (cached != null && cached.isNotEmpty) {
        _catatanList = cached
            .map((e) => CatatanKelahiranKematianModel.fromJson(
                  jsonDecode(e['json_data'] as String) as Map<String, dynamic>,
                ))
            .toList();
        debugPrint('[Catatan] Loaded ${_catatanList.length} from cache');
      }
    } catch (_) {}
  }

  /// Load detail single catatan
  Future<void> loadDetail(int id) async {
    _isLoading = true;
    _error = null;
    _selectedCatatan = null;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        _error = ApiException(message: 'Silakan login terlebih dahulu.');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final client = ApiClient(token: token);
      final response = await client.get(ApiEndpoints.catatanDetail(id));
      _selectedCatatan = CatatanKelahiranKematianModel.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      debugPrint('[Catatan] Error loading detail: $e');
      _error = ApiException(message: 'Gagal memuat detail catatan.');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Save catatan (create or update) with offline fallback
  Future<bool> saveCatatan(Map<String, dynamic> data, {int? id}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final isCreate = id == null;

      if (isCreate) {
        await client.post(ApiEndpoints.catatanKelahiranKematian, data: data);
      } else {
        await client.put(ApiEndpoints.catatanDetail(id), data: data);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      // Offer offline save
      try {
        await LocalDatabase().savePendingCatatan(data);
        debugPrint('[Catatan] Saved offline: ${data['id_warga_ibu']}');
      } catch (_) {}
      notifyListeners();
      return false;
    }
  }

  /// Delete catatan
  Future<bool> deleteCatatan(int id) async {
    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      await client.delete(ApiEndpoints.catatanDetail(id));

      _catatanList.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e;
      notifyListeners();
      return false;
    } catch (e) {
      _error = ApiException(message: 'Gagal menghapus catatan.');
      notifyListeners();
      return false;
    }
  }

  void setFilter(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
