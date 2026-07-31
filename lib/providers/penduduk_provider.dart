import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exception.dart';
import '../core/storage/local_storage.dart';
import '../database/local_database.dart';
import '../models/penduduk_model.dart';
import '../services/activity_service.dart';

class PendudukProvider extends ChangeNotifier {
  // Data dibagi dua: data server (API/cache) + data pending offline.
  // Getter pendudukList menggabungkan keduanya — data yang diinput offline
  // tampil paling atas dengan badge "Menunggu sinkron".
  List<PendudukModel> _serverList = [];
  List<PendudukModel> _pendingList = [];
  PendudukModel? _selectedPenduduk;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  ApiException? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  String _searchQuery = '';
  String? _filterJenisKelamin; // null = semua, 'L' = laki-laki, 'P' = perempuan

  List<PendudukModel> get pendudukList => [..._pendingList, ..._serverList];
  PendudukModel? get selectedPenduduk => _selectedPenduduk;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  ApiException? get error => _error;
  int get total => _total;
  String get searchQuery => _searchQuery;
  String? get filterJenisKelamin => _filterJenisKelamin;
  bool get hasMore => _currentPage < _lastPage;

  /// Filter jenis kelamin (server-side): null = semua, 'L'/'P'.
  void setFilterJenisKelamin(String? value) {
    if (_filterJenisKelamin == value) return;
    _filterJenisKelamin = value;
    loadPenduduk(refresh: true);
  }

  Future<void> loadPenduduk({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _serverList = [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    // Muat antrian offline agar data yang disimpan offline tetap tampil.
    await _loadPending();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'per_page': 25,
      };
      if (_searchQuery.isNotEmpty) queryParams['search'] = _searchQuery;
      if (_filterJenisKelamin != null) {
        queryParams['jenis_kelamin'] = _filterJenisKelamin;
      }

      final response = await client.get(ApiEndpoints.penduduk, queryParameters: queryParams);
      final data = response['data'] as List<dynamic>;
      final meta = response['meta'] as Map<String, dynamic>?;

      if (refresh) {
        _serverList = data.map((e) => PendudukModel.fromJson(e)).toList();
      } else {
        _serverList.addAll(data.map((e) => PendudukModel.fromJson(e)));
      }

      if (meta != null) {
        _currentPage = meta['current_page'] ?? 1;
        _lastPage = meta['last_page'] ?? 1;
        _total = meta['total'] ?? 0;
      }

      // Simpan ke cache agar saat offline berikutnya data tetap bisa dilihat.
      try {
        await LocalDatabase().cachePendudukList(data.cast<Map<String, dynamic>>());
      } catch (_) {}
    } on ApiException catch (e) {
      _error = e;
      await _fallbackToCache();
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat data penduduk.');
      await _fallbackToCache();
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
      if (_filterJenisKelamin != null) {
        queryParams['jenis_kelamin'] = _filterJenisKelamin;
      }

      final response = await client.get(ApiEndpoints.penduduk, queryParameters: queryParams);
      final data = response['data'] as List<dynamic>;
      final meta = response['meta'] as Map<String, dynamic>?;

      _serverList.addAll(data.map((e) => PendudukModel.fromJson(e)));
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

  /// Muat SELURUH data sekaligus (`per_page: 'all'`) — pengganti pemuatan
  /// bertahap. List lengkap ikut disimpan ke cache untuk kebutuhan offline.
  Future<void> loadAll() async {
    if (_isLoading || _isLoadingMore) return;

    _isLoadingMore = true;
    _error = null;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final queryParams = <String, dynamic>{
        'page': 1,
        'per_page': 'all',
      };
      if (_searchQuery.isNotEmpty) queryParams['search'] = _searchQuery;
      if (_filterJenisKelamin != null) {
        queryParams['jenis_kelamin'] = _filterJenisKelamin;
      }

      final response = await client.get(ApiEndpoints.penduduk, queryParameters: queryParams);
      final data = response['data'] as List<dynamic>;
      final meta = response['meta'] as Map<String, dynamic>?;

      _serverList = data.map((e) => PendudukModel.fromJson(e)).toList();
      // Semua data sudah dimuat -> footer "Muat lebih banyak" tidak perlu lagi.
      _currentPage = 1;
      _lastPage = 1;
      _total = meta?['total'] ?? data.length;

      // Simpan seluruh list ke cache agar offline menampilkan data lengkap.
      try {
        await LocalDatabase().cachePendudukList(data.cast<Map<String, dynamic>>());
      } catch (_) {}
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat seluruh data penduduk.');
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Muat ulang antrian offline (baris pending yang belum tersinkron).
  Future<void> _loadPending() async {
    try {
      final rows = await LocalDatabase().getUnsyncedPenduduk();
      _pendingList = rows
          .where((r) => r['action'] != 'DELETE')
          .map((r) => PendudukModel.fromJson(
                jsonDecode(r['json_data'] as String) as Map<String, dynamic>,
                isPendingSync: true,
              ))
          .toList();
    } catch (_) {}
  }

  /// Fallback offline: tampilkan data terakhir yang pernah diunduh.
  Future<void> _fallbackToCache() async {
    try {
      final cached = await LocalDatabase().getCachedPendudukList();
      if (cached.isNotEmpty) {
        _serverList = cached
            .map((e) => PendudukModel.fromJson(
                  jsonDecode(e['json_data'] as String) as Map<String, dynamic>,
                ))
            .toList();
        debugPrint('[Penduduk] Menampilkan ${_serverList.length} data dari cache');
      }
    } catch (_) {}
  }

  /// Cari penduduk di antrian offline (untuk dibuka saat offline).
  Future<PendudukModel?> _pendingByNik(String nik) async {
    try {
      final rows = await LocalDatabase().getUnsyncedPenduduk();
      for (final r in rows) {
        if (r['action'] == 'DELETE') continue;
        final json = jsonDecode(r['json_data'] as String) as Map<String, dynamic>;
        if (json['nik']?.toString() == nik) {
          return PendudukModel.fromJson(json, isPendingSync: true);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Cari penduduk di cache (data terakhir yang pernah diunduh).
  Future<PendudukModel?> _cachedByNik(String nik) async {
    try {
      final cached = await LocalDatabase().getCachedPendudukList();
      for (final e in cached) {
        final json = jsonDecode(e['json_data'] as String) as Map<String, dynamic>;
        if (json['nik']?.toString() == nik) {
          return PendudukModel.fromJson(json);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Detail: cek antrian offline dulu, lalu server, terakhir cache.
  Future<void> loadDetail(String nik) async {
    _isLoading = true;
    _error = null;
    _selectedPenduduk = null; // Clear previous selection
    notifyListeners();

    try {
      // 1) Data yang masih menunggu sinkron (disimpan offline).
      final pending = await _pendingByNik(nik);
      if (pending != null) {
        _selectedPenduduk = pending;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2) Server.
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final response = await client.get(ApiEndpoints.pendudukDetail(nik));
      _selectedPenduduk = PendudukModel.fromJson(response['data']);
    } on ApiException catch (e) {
      _error = e;
      // 3) Cache offline.
      _selectedPenduduk = await _cachedByNik(nik);
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat detail penduduk.');
      _selectedPenduduk = await _cachedByNik(nik);
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

  /// Hapus penduduk: online -> DELETE langsung ke server; offline/gagal
  /// jaringan -> antrikan DELETE untuk disinkronkan saat koneksi kembali.
  ///
  /// Mengembalikan record `(handled, queuedOffline)`: `handled=false` berarti
  /// operasi gagal (mis. response error dari server) dan tidak boleh dianggap
  /// terhapus; `queuedOffline=true` berarti data hanya diantrekan untuk sync.
  Future<({bool handled, bool queuedOffline})> deletePenduduk(PendudukModel p) async {
    final token = await LocalStorage.getToken();
    if (token == null) return (handled: false, queuedOffline: false);

    try {
      final client = ApiClient(token: token);
      await client.delete(ApiEndpoints.pendudukDetail(p.nik));

      _serverList.removeWhere((x) => x.nik == p.nik);
      _pendingList.removeWhere((x) => x.nik == p.nik);
      if (_total > 0) _total--;
      if (_selectedPenduduk?.nik == p.nik) _selectedPenduduk = null;

      await ActivityService().logDelete(
        tipe: 'Penduduk',
        nama: p.nama,
        identifier: '${p.nik} | Online',
      );
      notifyListeners();
      return (handled: true, queuedOffline: false);
    } on ApiException catch (e) {
      _error = e;
      notifyListeners();
      return (handled: false, queuedOffline: false);
    } catch (_) {
      // Gagal jaringan (bukan error server) -> antrikan DELETE offline.
      await LocalDatabase().queuePendingDeletePenduduk(p.nik, p.nama);
      await ActivityService().logDelete(
        tipe: 'Penduduk',
        nama: p.nama,
        identifier: '${p.nik} | Offline',
      );

      _serverList.removeWhere((x) => x.nik == p.nik);
      _pendingList.removeWhere((x) => x.nik == p.nik);
      if (_total > 0) _total--;
      if (_selectedPenduduk?.nik == p.nik) _selectedPenduduk = null;
      notifyListeners();
      return (handled: true, queuedOffline: true);
    }
  }
}
