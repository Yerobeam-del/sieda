import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/storage/local_storage.dart';
import '../database/local_database.dart';
import 'connectivity_service.dart';

class SyncService {
  final LocalDatabase _localDB = LocalDatabase();
  final ConnectivityService _connectivity;

  SyncService(this._connectivity);

  bool _isSyncing = false;
  int _pendingCount = 0;

  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;

  /// Sync all pending local data to server
  Future<SyncResult> syncAll() async {
    if (!_connectivity.isOnline) {
      return SyncResult(0, 0, 'Tidak ada koneksi internet.');
    }
    if (_isSyncing) {
      return SyncResult(0, 0, 'Sinkronisasi sedang berjalan...');
    }

    _isSyncing = true;
    int success = 0;
    int failed = 0;

    try {
      final token = await LocalStorage.getToken();
      if (token == null) return SyncResult(0, 0, 'Belum login.');

      final client = ApiClient(token: token);

      // Sync pending penduduk
      final pendingPenduduk = await _localDB.getUnsyncedPenduduk();
      for (final item in pendingPenduduk) {
        try {
          final data = _parseJson(item['json_data'] as String);
          await client.post(ApiEndpoints.penduduk, data: data);
          await _localDB.markPendudukSynced(item['id'] as int);
          success++;
        } catch (e) {
          failed++;
          debugPrint('[Sync] Gagal sync penduduk: $e');
        }
      }

      // Sync pending keluarga
      final pendingKeluarga = await _localDB.getUnsyncedKeluarga();
      for (final item in pendingKeluarga) {
        try {
          final data = _parseJson(item['json_data'] as String);
          await client.post(ApiEndpoints.keluarga, data: data);
          await _localDB.markKeluargaSynced(item['id'] as int);
          success++;
        } catch (e) {
          failed++;
          debugPrint('[Sync] Gagal sync keluarga: $e');
        }
      }

      // Sync pending catatan
      final pendingCatatan = await _localDB.getUnsyncedCatatan();
      for (final item in pendingCatatan) {
        try {
          final data = _parseJson(item['json_data'] as String);
          await client.post(ApiEndpoints.catatanKelahiranKematian, data: data);
          await _localDB.markCatatanSynced(item['id'] as int);
          success++;
        } catch (e) {
          failed++;
          debugPrint('[Sync] Gagal sync catatan: $e');
        }
      }

      // Sync pending dasawisma
      final pendingDasawisma = await _localDB.getUnsyncedDasawisma();
      for (final item in pendingDasawisma) {
        try {
          final data = _parseJson(item['json_data'] as String);
          final tipe = item['tipe'] as String;
          if (tipe == 'kelompok') {
            await client.post(ApiEndpoints.dasawismaKelompok, data: data);
          } else if (tipe == 'kesehatan') {
            await client.post(ApiEndpoints.dasawismaKeluarga, data: data);
          }
          await _localDB.markDasawismaSynced(item['id'] as int);
          success++;
        } catch (e) {
          failed++;
          debugPrint('[Sync] Gagal sync dasawisma: $e');
        }
      }

      // Update count
      _pendingCount = await _countPending();
    } catch (e) {
      debugPrint('[Sync] Error: $e');
    }

    _isSyncing = false;
    return SyncResult(success, failed, failed > 0 ? '$failed data gagal disync' : 'Semua berhasil disync');
  }

  Future<int> _countPending() async {
    final penduduk = await _localDB.getUnsyncedPenduduk();
    final keluarga = await _localDB.getUnsyncedKeluarga();
    final catatan = await _localDB.getUnsyncedCatatan();
    final dasawisma = await _localDB.getUnsyncedDasawisma();
    return penduduk.length + keluarga.length + catatan.length + dasawisma.length;
  }

  Map<String, dynamic> _parseJson(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[Sync] Gagal parse JSON: $e');
      return {};
    }
  }
}

class SyncResult {
  final int success;
  final int failed;
  final String message;

  SyncResult(this.success, this.failed, this.message);
}
