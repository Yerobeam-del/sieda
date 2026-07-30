import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exception.dart';
import '../core/storage/local_storage.dart';
import '../database/local_database.dart';
import '../models/dasawisma_model.dart';

class DasawismaProvider extends ChangeNotifier {
  List<KelompokDasawismaModel> _kelompokList = [];
  List<RingkasanPerDusun> _ringkasanList = [];
  List<DasawismaKesehatanModel> _recapKesehatanList = [];
  List<DasawismaKeluargaData> _dasawismaKeluargaList = [];
  KelompokDasawismaModel? _selectedKelompok;
  bool _isLoading = false;
  ApiException? _error;
  int? _filterDusunId;

  List<KelompokDasawismaModel> get kelompokList => _kelompokList;
  List<RingkasanPerDusun> get ringkasanList => _ringkasanList;
  List<DasawismaKesehatanModel> get recapKesehatanList => _recapKesehatanList;
  List<DasawismaKeluargaData> get dasawismaKeluargaList => _dasawismaKeluargaList;
  KelompokDasawismaModel? get selectedKelompok => _selectedKelompok;
  bool get isLoading => _isLoading;
  ApiException? get error => _error;
  int? get filterDusunId => _filterDusunId;

  // ==================== KELOMPOK CRUD ====================

  Future<void> loadKelompok({bool refresh = false}) async {
    if (refresh) _kelompokList = [];
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final params = <String, dynamic>{};
      if (_filterDusunId != null) params['id_dusun'] = _filterDusunId;

      final response = await client.get(ApiEndpoints.dasawismaKelompok, queryParameters: params);
      final data = response['data'] as List<dynamic>;
      _kelompokList = data.map((e) => KelompokDasawismaModel.fromJson(e as Map<String, dynamic>)).toList();

      try { await LocalDatabase().cacheDasawismaKelompok(data.cast<Map<String, dynamic>>()); } catch (_) {}
    } on ApiException catch (e) {
      _error = e;
      await _loadKelompokCache();
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat kelompok dasawisma.');
      await _loadKelompokCache();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadKelompokCache() async {
    try {
      final cached = await LocalDatabase().getCachedDasawismaKelompok();
      if (cached != null) {
        _kelompokList = cached.map((e) => KelompokDasawismaModel.fromJson(
          jsonDecode(e['json_data'] as String) as Map<String, dynamic>,
        )).toList();
      }
    } catch (_) {}
  }

  Future<bool> saveKelompok(Map<String, dynamic> data, {int? id}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      if (id != null) {
        await client.put(ApiEndpoints.dasawismaKelompokDetail(id), data: data);
      } else {
        await client.post(ApiEndpoints.dasawismaKelompok, data: data);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = ApiException(message: 'Gagal menyimpan kelompok.');
      await LocalDatabase().savePendingDasawisma(data, 'kelompok');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteKelompok(int id) async {
    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      await client.delete(ApiEndpoints.dasawismaKelompokDetail(id));
      _kelompokList.removeWhere((k) => k.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e;
      notifyListeners();
      return false;
    } catch (e) {
      _error = ApiException(message: 'Gagal menghapus kelompok.');
      notifyListeners();
      return false;
    }
  }

  Future<void> loadKelompokDetail(int id) async {
    _isLoading = true;
    _error = null;
    _selectedKelompok = null;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final response = await client.get(ApiEndpoints.dasawismaKelompokDetail(id));
      _selectedKelompok = KelompokDasawismaModel.fromJson(response['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat detail kelompok.');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ==================== DASAWISMA KELUARGA (KESEHATAN) ====================

  Future<void> loadDasawismaKeluarga({String? noKK}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final params = <String, dynamic>{'per_page': 'all'};
      if (noKK != null) params['no_kk'] = noKK;

      final response = await client.get(ApiEndpoints.dasawismaKeluarga, queryParameters: params);
      final data = response['data'] as List<dynamic>;
      _dasawismaKeluargaList = data.map((e) => DasawismaKeluargaData.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat data kesehatan keluarga.');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveDasawismaKeluarga(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      await client.post(ApiEndpoints.dasawismaKeluarga, data: data);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = ApiException(message: 'Gagal menyimpan data kesehatan.');
      await LocalDatabase().savePendingDasawisma(data, 'kesehatan');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ==================== RINGKASAN & KESEHATAN ====================

  Future<void> loadRingkasan() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final response = await client.get(ApiEndpoints.dasawismaRingkasan);
      final data = response['data'] as List<dynamic>;
      _ringkasanList = data.map((e) => RingkasanPerDusun.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat ringkasan.');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRecapKesehatan() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final response = await client.get(ApiEndpoints.dasawismaRecapKesehatan);
      final data = response['data'] as List<dynamic>;
      _recapKesehatanList = data.map((e) => DasawismaKesehatanModel.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat rekap kesehatan.');
    }

    _isLoading = false;
    notifyListeners();
  }

  void setFilterDusun(int? dusunId) {
    _filterDusunId = dusunId;
    loadKelompok(refresh: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
