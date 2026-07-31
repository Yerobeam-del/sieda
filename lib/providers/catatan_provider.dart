import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exception.dart';
import '../core/storage/local_storage.dart';
import '../database/local_database.dart';
import '../models/catatan_model.dart';

class CatatanProvider extends ChangeNotifier {
  // Data dibagi dua: data server (API/cache) + data pending offline.
  // Getter catatanList menggabungkan keduanya — data yang diinput offline
  // tampil paling atas dengan badge "Menunggu sinkron".
  List<CatatanKelahiranKematianModel> _serverList = [];
  List<CatatanKelahiranKematianModel> _pendingList = [];
  CatatanKelahiranKematianModel? _selectedCatatan;
  bool _isLoading = false;
  ApiException? _error;
  String _filterStatus = 'all'; // all, hamil, melahirkan, nifas, meninggal
  String _searchQuery = '';
  int? _filterTahun; // null = semua tahun

  List<CatatanKelahiranKematianModel> get catatanList => [..._pendingList, ..._serverList];
  CatatanKelahiranKematianModel? get selectedCatatan => _selectedCatatan;
  bool get isLoading => _isLoading;
  ApiException? get error => _error;
  String get filterStatus => _filterStatus;
  String get searchQuery => _searchQuery;
  int? get filterTahun => _filterTahun;

  /// Tahun yang tersedia di data (descending) — untuk chip filter tahun.
  List<int> get availableYears {
    final years = catatanList
        .map((c) => c.configYear)
        .where((y) => y > 0)
        .toSet()
        .toList();
    years.sort((a, b) => b.compareTo(a));
    return years;
  }

  /// Ada filter aktif selain "Semua" (untuk pesan empty state).
  bool get hasActiveFilter =>
      _filterStatus != 'all' || _filterTahun != null || _searchQuery.isNotEmpty;

  List<CatatanKelahiranKematianModel> get filteredList {
    return catatanList.where((c) {
      // Status (hamil/melahirkan/nifas/meninggal)
      if (_filterStatus != 'all') {
        if (_filterStatus == 'death') {
          if (!c.isDeath) return false;
        } else if (c.statusIbu?.toLowerCase() != _filterStatus) {
          return false;
        }
      }
      // Tahun
      if (_filterTahun != null && c.configYear != _filterTahun) {
        return false;
      }
      // Pencarian teks (nama ibu/suami/bayi/meninggal, status, kelompok)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final haystack = [
          c.namaIbu,
          c.namaSuami,
          c.namaBayi,
          c.namaMeninggal,
          c.statusIbu,
          c.statusKematian,
          c.namaKelompok,
        ].whereType<String>().join(' ').toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  /// Pencarian teks (klien-side — list dimuat penuh tanpa paginasi).
  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Filter tahun (null = semua tahun).
  void setFilterTahun(int? tahun) {
    _filterTahun = tahun;
    notifyListeners();
  }

  /// Reset semua filter ke default.
  void clearFilters() {
    _filterStatus = 'all';
    _filterTahun = null;
    _searchQuery = '';
    notifyListeners();
  }

  /// Load all catatan from API, fallback to cache
  Future<void> loadCatatan({bool refresh = false}) async {
    if (refresh) {
      _serverList = [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    // Muat antrian offline agar data yang disimpan offline tetap tampil.
    await _loadPending();

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

      _serverList = data
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

  /// Muat ulang antrian offline (baris pending yang belum tersinkron).
  Future<void> _loadPending() async {
    try {
      final rows = await LocalDatabase().getUnsyncedCatatan();
      _pendingList = rows
          .where((r) => r['action'] != 'DELETE')
          .map((r) => CatatanKelahiranKematianModel.fromJson(
                jsonDecode(r['json_data'] as String) as Map<String, dynamic>,
                isPendingSync: true,
              ))
          .toList();
    } catch (_) {}
  }

  Future<void> _loadFromCache() async {
    try {
      final cached = await LocalDatabase().getCachedCatatan();
      if (cached != null && cached.isNotEmpty) {
        _serverList = cached
            .map((e) => CatatanKelahiranKematianModel.fromJson(
                  jsonDecode(e['json_data'] as String) as Map<String, dynamic>,
                ))
            .toList();
        debugPrint('[Catatan] Loaded ${_serverList.length} from cache');
      }
    } catch (_) {}
  }

  /// Cari catatan di antrian offline (untuk dibuka saat offline).
  /// CREATE baru offline tidak punya id server → id 0 memetakan ke baris
  /// tanpa id.
  Future<CatatanKelahiranKematianModel?> _pendingById(int id) async {
    try {
      final rows = await LocalDatabase().getUnsyncedCatatan();
      for (final r in rows) {
        if (r['action'] == 'DELETE') continue;
        final json = jsonDecode(r['json_data'] as String) as Map<String, dynamic>;
        final rowId = json['id']?.toString();
        if (id == 0
            ? (rowId == null || rowId.isEmpty)
            : rowId == id.toString()) {
          return CatatanKelahiranKematianModel.fromJson(json, isPendingSync: true);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Cari catatan di cache (data terakhir yang pernah diunduh).
  Future<CatatanKelahiranKematianModel?> _cachedById(int id) async {
    try {
      final cached = await LocalDatabase().getCachedCatatan();
      if (cached == null) return null;
      for (final e in cached) {
        final json = jsonDecode(e['json_data'] as String) as Map<String, dynamic>;
        if (json['id']?.toString() == id.toString()) {
          return CatatanKelahiranKematianModel.fromJson(json);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Load detail single catatan
  Future<void> loadDetail(int id) async {
    _isLoading = true;
    _error = null;
    _selectedCatatan = null;
    notifyListeners();

    try {
      // 1) Data yang masih menunggu sinkron (disimpan offline).
      final pending = await _pendingById(id);
      if (pending != null) {
        _selectedCatatan = pending;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2) Server.
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
      // 3) Cache offline.
      _selectedCatatan = await _cachedById(id);
    } catch (e) {
      debugPrint('[Catatan] Error loading detail: $e');
      _error = ApiException(message: 'Gagal memuat detail catatan.');
      _selectedCatatan = await _cachedById(id);
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
        await LocalDatabase().savePendingCatatan(
          data,
          action: id != null ? 'UPDATE' : 'CREATE',
        );
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

      _serverList.removeWhere((c) => c.id == id);
      _pendingList.removeWhere((c) => c.id == id);
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
