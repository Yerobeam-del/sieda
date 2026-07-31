import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exception.dart';
import '../core/storage/local_storage.dart';
import '../database/local_database.dart';
import '../models/dasawisma_model.dart';
import '../services/activity_service.dart';

class DasawismaProvider extends ChangeNotifier {
  // Data dibagi dua: data server (API/cache) + data pending offline.
  // Getter di bawah menggabungkan keduanya — data yang diinput offline
  // tampil paling atas dengan badge "Menunggu sinkron".
  List<KelompokDasawismaModel> _serverKelompokList = [];
  List<KelompokDasawismaModel> _pendingKelompokList = [];
  List<RingkasanPerDusun> _ringkasanList = [];
  List<DasawismaKesehatanModel> _recapKesehatanList = [];
  List<DasawismaKeluargaData> _serverDasawismaKeluargaList = [];
  List<DasawismaKeluargaData> _pendingDasawismaKeluargaList = [];
  KelompokDasawismaModel? _selectedKelompok;
  bool _isLoading = false;
  ApiException? _error;
  int? _filterDusunId;

  List<KelompokDasawismaModel> get kelompokList => [..._pendingKelompokList, ..._serverKelompokList];
  List<RingkasanPerDusun> get ringkasanList => _ringkasanList;
  List<DasawismaKesehatanModel> get recapKesehatanList => _recapKesehatanList;
  List<DasawismaKeluargaData> get dasawismaKeluargaList =>
      [..._pendingDasawismaKeluargaList, ..._serverDasawismaKeluargaList];
  KelompokDasawismaModel? get selectedKelompok => _selectedKelompok;
  bool get isLoading => _isLoading;
  ApiException? get error => _error;
  int? get filterDusunId => _filterDusunId;

  // ==================== KELOMPOK CRUD ====================

  Future<void> loadKelompok({bool refresh = false}) async {
    if (refresh) _serverKelompokList = [];
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Muat antrian offline agar data yang disimpan offline tetap tampil.
    await _loadPendingKelompok();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final params = <String, dynamic>{};
      if (_filterDusunId != null) params['id_dusun'] = _filterDusunId;

      final response = await client.get(ApiEndpoints.dasawismaKelompok, queryParameters: params);
      final data = response['data'] as List<dynamic>;
      _serverKelompokList = data.map((e) => KelompokDasawismaModel.fromJson(e as Map<String, dynamic>)).toList();

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

  /// Muat antrian kelompok dasawisma yang belum tersinkron.
  Future<void> _loadPendingKelompok() async {
    try {
      final rows = await LocalDatabase().getUnsyncedDasawisma();
      _pendingKelompokList = rows
          .where((r) => r['tipe'] == 'kelompok' && r['action'] != 'DELETE')
          .map((r) => KelompokDasawismaModel.fromJson(
                jsonDecode(r['json_data'] as String) as Map<String, dynamic>,
                isPendingSync: true,
              ))
          .toList();
    } catch (_) {}
  }

  /// Muat antrian data kesehatan keluarga yang belum tersinkron.
  Future<void> _loadPendingDasawismaKeluarga() async {
    try {
      final rows = await LocalDatabase().getUnsyncedDasawisma();
      _pendingDasawismaKeluargaList = rows
          .where((r) => r['tipe'] == 'kesehatan' && r['action'] != 'DELETE')
          .map((r) => DasawismaKeluargaData.fromJson(
                jsonDecode(r['json_data'] as String) as Map<String, dynamic>,
                isPendingSync: true,
              ))
          .toList();
    } catch (_) {}
  }

  Future<void> _loadKelompokCache() async {
    try {
      final cached = await LocalDatabase().getCachedDasawismaKelompok();
      if (cached != null) {
        _serverKelompokList = cached.map((e) => KelompokDasawismaModel.fromJson(
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
      // statusCode 0 = error koneksi (timeout/refused) — antrikan offline.
      if (e.statusCode == 0) {
        await LocalDatabase().savePendingDasawisma(data, 'kelompok',
            action: id != null ? 'UPDATE' : 'CREATE');
      }
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

  /// Hapus kelompok. Jika gagal karena tidak ada koneksi (bukan error HTTP),
  /// penghapusan diantrikan offline agar terkirim saat koneksi kembali.
  Future<bool> deleteKelompok(int id) async {
    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      await client.delete(ApiEndpoints.dasawismaKelompokDetail(id));
      _serverKelompokList.removeWhere((k) => k.id == id);
      _pendingKelompokList.removeWhere((k) => k.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e;
      notifyListeners();
      return false;
    } catch (e) {
      // Offline: antrikan DELETE agar terkirim saat koneksi kembali.
      await LocalDatabase().queuePendingDeleteDasawismaKelompok(id);
      await ActivityService().logDelete(
        tipe: 'Dasawisma',
        nama: 'Kelompok #$id',
        identifier: 'id: $id | Offline',
      );
      _serverKelompokList.removeWhere((k) => k.id == id);
      _pendingKelompokList.removeWhere((k) => k.id == id);
      notifyListeners();
      return true;
    }
  }

  Future<void> loadKelompokDetail(int id) async {
    _isLoading = true;
    _error = null;
    _selectedKelompok = null;
    notifyListeners();

    try {
      // 1) Data yang masih menunggu sinkron (disimpan offline).
      final pending = await _pendingKelompokById(id);
      if (pending != null) {
        _selectedKelompok = pending;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2) Server.
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final response = await client.get(ApiEndpoints.dasawismaKelompokDetail(id));
      _selectedKelompok = KelompokDasawismaModel.fromJson(response['data'] as Map<String, dynamic>);
    } on ApiException catch (e) {
      _error = e;
      // 3) Cache offline.
      _selectedKelompok = await _cachedKelompokById(id);
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat detail kelompok.');
      _selectedKelompok = await _cachedKelompokById(id);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<KelompokDasawismaModel?> _pendingKelompokById(int id) async {
    try {
      final rows = await LocalDatabase().getUnsyncedDasawisma();
      for (final r in rows) {
        if (r['tipe'] != 'kelompok' || r['action'] == 'DELETE') continue;
        final json = jsonDecode(r['json_data'] as String) as Map<String, dynamic>;
        if (json['id']?.toString() == id.toString()) {
          return KelompokDasawismaModel.fromJson(json, isPendingSync: true);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<KelompokDasawismaModel?> _cachedKelompokById(int id) async {
    try {
      final cached = await LocalDatabase().getCachedDasawismaKelompok();
      if (cached == null) return null;
      for (final e in cached) {
        final json = jsonDecode(e['json_data'] as String) as Map<String, dynamic>;
        if (json['id']?.toString() == id.toString()) {
          return KelompokDasawismaModel.fromJson(json);
        }
      }
    } catch (_) {}
    return null;
  }

  // ==================== DASAWISMA KELUARGA (KESEHATAN) ====================

  Future<void> loadDasawismaKeluarga({String? noKK}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Muat antrian offline agar data yang disimpan offline tetap tampil.
    await _loadPendingDasawismaKeluarga();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final params = <String, dynamic>{'per_page': 'all'};
      if (noKK != null) params['no_kk'] = noKK;

      final response = await client.get(ApiEndpoints.dasawismaKeluarga, queryParameters: params);
      final data = response['data'] as List<dynamic>;
      _serverDasawismaKeluargaList = data.map((e) => DasawismaKeluargaData.fromJson(e as Map<String, dynamic>)).toList();
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
      // statusCode 0 = error koneksi (timeout/refused) — antrikan offline.
      if (e.statusCode == 0) {
        await LocalDatabase().savePendingDasawisma(data, 'kesehatan');
      }
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

  /// Hapus data kesehatan keluarga. Jika gagal karena tidak ada koneksi
  /// (bukan error HTTP), penghapusan diantrikan offline agar terkirim saat
  /// koneksi kembali.
  Future<bool> deleteDasawismaKeluarga(String noKK) async {
    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      await client.delete(ApiEndpoints.dasawismaKeluargaDetail(noKK));
      _serverDasawismaKeluargaList.removeWhere((k) => k.noKK == noKK);
      _pendingDasawismaKeluargaList.removeWhere((k) => k.noKK == noKK);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e;
      notifyListeners();
      return false;
    } catch (e) {
      // Offline: antrikan DELETE agar terkirim saat koneksi kembali.
      await LocalDatabase().queuePendingDeleteDasawismaKeluarga(noKK);
      await ActivityService().logDelete(
        tipe: 'Dasawisma',
        nama: 'Data kesehatan No. KK $noKK',
        identifier: 'no_kk: $noKK | Offline',
      );
      _serverDasawismaKeluargaList.removeWhere((k) => k.noKK == noKK);
      _pendingDasawismaKeluargaList.removeWhere((k) => k.noKK == noKK);
      notifyListeners();
      return true;
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
