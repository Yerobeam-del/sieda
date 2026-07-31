import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exception.dart';
import '../core/storage/local_storage.dart';
import '../database/local_database.dart';
import '../models/keluarga_model.dart';
import '../services/activity_service.dart';

class KeluargaProvider extends ChangeNotifier {
  // Data dibagi dua: data server (API/cache) + data pending offline.
  // Getter keluargaList menggabungkan keduanya — data yang diinput offline
  // tampil paling atas dengan badge "Menunggu sinkron".
  List<KeluargaModel> _serverList = [];
  List<KeluargaModel> _pendingList = [];
  KeluargaModel? _selectedKeluarga;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  ApiException? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  int _total = 0;
  String _searchQuery = '';

  List<KeluargaModel> get keluargaList => [..._pendingList, ..._serverList];
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
      queryParams['with'] = 'kepala_keluarga,kelompok_dasawisma';

      final response = await client.get(ApiEndpoints.keluarga, queryParameters: queryParams);
      final data = response['data'] as List<dynamic>;
      final meta = response['meta'] as Map<String, dynamic>?;

      if (refresh) {
        _serverList = data.map((e) => KeluargaModel.fromJson(e)).toList();
      } else {
        _serverList.addAll(data.map((e) => KeluargaModel.fromJson(e)));
      }

      if (meta != null) {
        _currentPage = meta['current_page'] ?? 1;
        _lastPage = meta['last_page'] ?? 1;
        _total = meta['total'] ?? 0;
      }

      // Simpan ke cache agar saat offline berikutnya data tetap bisa dilihat.
      try {
        await LocalDatabase().cacheKeluargaList(data.cast<Map<String, dynamic>>());
      } catch (_) {}
    } on ApiException catch (e) {
      _error = e;
      await _fallbackToCache();
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat data keluarga.');
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

      _serverList.addAll(data.map((e) => KeluargaModel.fromJson(e)));
      if (meta != null) {
        _currentPage = meta['current_page'] ?? _currentPage;
        _lastPage = meta['last_page'] ?? _lastPage;
        _total = meta['total'] ?? _total;
      }
    } catch (_) {}

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
        'with': 'kepala_keluarga,kelompok_dasawisma',
      };
      if (_searchQuery.isNotEmpty) queryParams['search'] = _searchQuery;

      final response = await client.get(ApiEndpoints.keluarga, queryParameters: queryParams);
      final data = response['data'] as List<dynamic>;
      final meta = response['meta'] as Map<String, dynamic>?;

      _serverList = data.map((e) => KeluargaModel.fromJson(e)).toList();
      // Semua data sudah dimuat -> footer "Muat lebih banyak" tidak perlu lagi.
      _currentPage = 1;
      _lastPage = 1;
      _total = meta?['total'] ?? data.length;

      // Simpan seluruh list ke cache agar offline menampilkan data lengkap.
      try {
        await LocalDatabase().cacheKeluargaList(data.cast<Map<String, dynamic>>());
      } catch (_) {}
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat seluruh data keluarga.');
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  /// Muat ulang antrian offline (baris pending yang belum tersinkron).
  Future<void> _loadPending() async {
    try {
      final rows = await LocalDatabase().getUnsyncedKeluarga();
      _pendingList = rows
          .where((r) => r['action'] != 'DELETE')
          .map((r) => KeluargaModel.fromJson(
                jsonDecode(r['json_data'] as String) as Map<String, dynamic>,
                isPendingSync: true,
              ))
          .toList();
    } catch (_) {}
  }

  /// Fallback offline: tampilkan data terakhir yang pernah diunduh.
  Future<void> _fallbackToCache() async {
    try {
      final cached = await LocalDatabase().getCachedKeluargaList();
      if (cached.isNotEmpty) {
        _serverList = cached
            .map((e) => KeluargaModel.fromJson(
                  jsonDecode(e['json_data'] as String) as Map<String, dynamic>,
                ))
            .toList();
        debugPrint('[Keluarga] Menampilkan ${_serverList.length} data dari cache');
      }
    } catch (_) {}
  }

  /// Cari keluarga di antrian offline (untuk dibuka saat offline).
  Future<KeluargaModel?> _pendingByNoKk(String noKk) async {
    try {
      final rows = await LocalDatabase().getUnsyncedKeluarga();
      for (final r in rows) {
        if (r['action'] == 'DELETE') continue;
        final json = jsonDecode(r['json_data'] as String) as Map<String, dynamic>;
        if (json['no_kk']?.toString() == noKk) {
          return KeluargaModel.fromJson(json, isPendingSync: true);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Cari keluarga di cache (data terakhir yang pernah diunduh).
  Future<KeluargaModel?> _cachedByNoKk(String noKk) async {
    try {
      final cached = await LocalDatabase().getCachedKeluargaList();
      for (final e in cached) {
        final json = jsonDecode(e['json_data'] as String) as Map<String, dynamic>;
        if (json['no_kk']?.toString() == noKk) {
          return KeluargaModel.fromJson(json);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Detail: cek antrian offline dulu, lalu server, terakhir cache.
  Future<void> loadDetail(String noKk) async {
    _isLoading = true;
    _error = null;
    _selectedKeluarga = null; // Clear previous selection
    notifyListeners();

    try {
      // 1) Data yang masih menunggu sinkron (disimpan offline).
      final pending = await _pendingByNoKk(noKk);
      if (pending != null) {
        _selectedKeluarga = pending;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2) Server.
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final response = await client.get(ApiEndpoints.keluargaDetail(noKk));
      _selectedKeluarga = KeluargaModel.fromJson(response['data']);
    } on ApiException catch (e) {
      _error = e;
      // 3) Cache offline.
      _selectedKeluarga = await _cachedByNoKk(noKk);
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat detail keluarga.');
      _selectedKeluarga = await _cachedByNoKk(noKk);
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

  /// Hapus keluarga: online -> DELETE langsung ke server; offline/gagal
  /// jaringan -> antrikan DELETE untuk disinkronkan saat koneksi kembali.
  ///
  /// Mengembalikan record `(handled, queuedOffline)`: `handled=false` berarti
  /// operasi gagal (mis. response error dari server) dan tidak boleh dianggap
  /// terhapus; `queuedOffline=true` berarti data hanya diantrekan untuk sync.
  Future<({bool handled, bool queuedOffline})> deleteKeluarga(KeluargaModel k) async {
    final token = await LocalStorage.getToken();
    if (token == null) return (handled: false, queuedOffline: false);

    final nama = k.kepalaKeluarga?.nama ?? 'Keluarga ${k.noKk}';

    try {
      final client = ApiClient(token: token);
      await client.delete(ApiEndpoints.keluargaDetail(k.noKk));

      _serverList.removeWhere((x) => x.noKk == k.noKk);
      _pendingList.removeWhere((x) => x.noKk == k.noKk);
      if (_total > 0) _total--;
      if (_selectedKeluarga?.noKk == k.noKk) _selectedKeluarga = null;

      await ActivityService().logDelete(
        tipe: 'Keluarga',
        nama: nama,
        identifier: '${k.noKk} | Online',
      );
      notifyListeners();
      return (handled: true, queuedOffline: false);
    } on ApiException catch (e) {
      _error = e;
      notifyListeners();
      return (handled: false, queuedOffline: false);
    } catch (_) {
      // Gagal jaringan (bukan error server) -> antrikan DELETE offline.
      await LocalDatabase().queuePendingDeleteKeluarga(k.noKk);
      await ActivityService().logDelete(
        tipe: 'Keluarga',
        nama: nama,
        identifier: '${k.noKk} | Offline',
      );

      _serverList.removeWhere((x) => x.noKk == k.noKk);
      _pendingList.removeWhere((x) => x.noKk == k.noKk);
      if (_total > 0) _total--;
      if (_selectedKeluarga?.noKk == k.noKk) _selectedKeluarga = null;
      notifyListeners();
      return (handled: true, queuedOffline: true);
    }
  }
}
