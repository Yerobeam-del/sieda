import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/storage/local_storage.dart';
import '../database/local_database.dart';
import 'activity_service.dart';
import 'connectivity_service.dart';

class SyncService {
  final LocalDatabase _localDB = LocalDatabase();
  final ConnectivityService _connectivity;

  SyncService(this._connectivity);

  bool _isSyncing = false;
  int _pendingCount = 0;

  bool get isSyncing => _isSyncing;
  int get pendingCount => _pendingCount;

  /// Sync all pending local data to server.
  ///
  /// Hanya item yang berhasil dikirim yang ditandai synced — item dengan tipe
  /// yang tidak dikenal TIDAK dihapus dari antrian (mencegah kehilangan data).
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
    int deferred = 0;
    final byTypeSuccess = <String, int>{};
    final byTypeFailed = <String, int>{};
    final failures = <String>[];
    final deferredItems = <String>[];

    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        _isSyncing = false;
        return SyncResult(0, 0, 'Belum login.');
      }

      final client = ApiClient(token: token);

      void record(String type, bool ok, {String? error}) {
        if (ok) {
          success++;
          byTypeSuccess[type] = (byTypeSuccess[type] ?? 0) + 1;
        } else {
          failed++;
          byTypeFailed[type] = (byTypeFailed[type] ?? 0) + 1;
          if (error != null) failures.add(error);
        }
      }

      // Sync pending penduduk (hanya item yang siap dicoba ulang)
      final pendingPenduduk = await _localDB.getPendingReady('pending_penduduk');
      for (final item in pendingPenduduk) {
        final id = item['id'] as int;
        final action = item['action'] as String? ?? 'CREATE';
        final attempt = (item['retry_count'] as int? ?? 0) + 1;
        try {
          final data = _parseJson(item['json_data'] as String);
          final nik = data['nik'] as String? ?? '';
          if (action == 'DELETE') {
            await client.delete(ApiEndpoints.pendudukDetail(nik));
          } else if (action == 'UPDATE') {
            await client.put(ApiEndpoints.pendudukDetail(nik), data: data);
          } else {
            await client.post(ApiEndpoints.penduduk, data: data);
          }
          await _localDB.markPendudukSynced(id);
          record('Penduduk', true);
        } catch (e) {
          debugPrint('[Sync] Gagal sync penduduk ($action): $e');
          await _localDB.markPendingFailed('pending_penduduk', id, _shortError(e));
          record('Penduduk', false, error: '[Penduduk:$action] percobaan $attempt: ${_shortError(e)}');
        }
      }

      // Sync pending keluarga (hanya item yang siap dicoba ulang)
      final pendingKeluarga = await _localDB.getPendingReady('pending_keluarga');
      for (final item in pendingKeluarga) {
        final id = item['id'] as int;
        final action = item['action'] as String? ?? 'CREATE';
        final attempt = (item['retry_count'] as int? ?? 0) + 1;
        try {
          final data = _parseJson(item['json_data'] as String);
          final noKk = data['no_kk'] as String? ?? '';
          if (action == 'DELETE') {
            await client.delete(ApiEndpoints.keluargaDetail(noKk));
          } else if (action == 'UPDATE') {
            await client.put(ApiEndpoints.keluargaDetail(noKk), data: data);
          } else {
            await client.post(ApiEndpoints.keluarga, data: data);
          }
          await _localDB.markKeluargaSynced(id);
          record('Keluarga', true);
        } catch (e) {
          debugPrint('[Sync] Gagal sync keluarga ($action): $e');
          await _localDB.markPendingFailed('pending_keluarga', id, _shortError(e));
          record('Keluarga', false, error: '[Keluarga:$action] percobaan $attempt: ${_shortError(e)}');
        }
      }

      // Kumpulan no_kk keluarga yang MASIH pending setelah loop keluarga di atas
      // (gagal terkirim atau belum ada di server). Dasawisma kesehatan yang
      // merujuk no_kk ini harus DITUNDA: server menolak karena no_kk belum ada
      // di tabel tp_pkk_keluarga (validasi exists).
      //
      // Keluarga yang diantre DELETE tidak ikut menahan — dasawisma kesehatan
      // baru untuk keluarga yang sedang dihapus adalah data kontradiktif dan
      // tidak seharusnya ditunda oleh penghapusan tersebut.
      final sisaKeluargaPending = await _localDB.getUnsyncedKeluarga();
      final noKkKeluargaBelumSync = sisaKeluargaPending
          .where((item) => (item['action'] as String? ?? 'CREATE') != 'DELETE')
          .map((item) => item['no_kk'] as String?)
          .whereType<String>()
          .toSet();

      // Sync pending catatan (hanya item yang siap dicoba ulang)
      final pendingCatatan = await _localDB.getPendingReady('pending_catatan');
      for (final item in pendingCatatan) {
        final id = item['id'] as int;
        final action = item['action'] as String? ?? 'CREATE';
        final attempt = (item['retry_count'] as int? ?? 0) + 1;
        try {
          final data = _parseJson(item['json_data'] as String);

          // Pre-sync validation: server memvalidasi no_kk exists di tp_pkk_keluarga
          // (dan menurunkan id_group_dasawisma dari keluarga tersebut). Catatan yang
          // merujuk keluarga yang masih pending harus DITUNDA sampai keluarga terkirim,
          // persis seperti deferral anggota & dasawisma di bawah.
          final noKk = data['no_kk'] as String?;
          if (action != 'DELETE' && noKk != null && noKkKeluargaBelumSync.contains(noKk)) {
            deferred++;
            deferredItems.add('Catatan no_kk $noKk (menunggu keluarga tersinkronkan)');
            debugPrint('[Sync] Tunda catatan no_kk $noKk: keluarga belum terkirim.');
            continue;
          }

          if (action == 'DELETE') {
            final catatanId = data['id'] as int? ?? 0;
            await client.delete(ApiEndpoints.catatanDetail(catatanId));
          } else if (action == 'UPDATE') {
            final catatanId = data['id'] as int? ?? 0;
            // Strip id dari payload agar identik dengan jalur online (PUT
            // mengidentifikasi via URL, bukan body).
            await client.put(ApiEndpoints.catatanDetail(catatanId), data: _withoutId(data));
          } else {
            await client.post(ApiEndpoints.catatanKelahiranKematian, data: data);
          }
          await _localDB.markCatatanSynced(id);
          record('Catatan', true);
        } catch (e) {
          debugPrint('[Sync] Gagal sync catatan ($action): $e');
          await _localDB.markPendingFailed('pending_catatan', id, _shortError(e));
          record('Catatan', false, error: '[Catatan:$action] percobaan $attempt: ${_shortError(e)}');
        }
      }

      // Sync pending dasawisma (kelompok & kesehatan keluarga) — hanya item siap retry
      final pendingDasawisma = await _localDB.getPendingReady('pending_dasawisma');
      for (final item in pendingDasawisma) {
        final tipe = item['tipe'] as String? ?? '';
        final action = item['action'] as String? ?? 'CREATE';
        final id = item['id'] as int;
        final attempt = (item['retry_count'] as int? ?? 0) + 1;
        try {
          final data = _parseJson(item['json_data'] as String);
          bool posted = false;

          // Aksi DELETE: hapus langsung di endpoint detail.
          if (action == 'DELETE') {
            if (tipe == 'kelompok') {
              final kelompokId = data['id'] as int? ?? 0;
              await client.delete(ApiEndpoints.dasawismaKelompokDetail(kelompokId));
              posted = true;
            } else if (tipe == 'kesehatan') {
              final noKk = data['no_kk'] as String? ?? '';
              await client.delete(ApiEndpoints.dasawismaKeluargaDetail(noKk));
              posted = true;
            }
          } else if (tipe == 'kelompok') {
            if (action == 'UPDATE') {
              final kelompokId = data['id'] as int? ?? 0;
              // Strip id dari payload agar identik dengan jalur online.
              await client.put(ApiEndpoints.dasawismaKelompokDetail(kelompokId), data: _withoutId(data));
            } else {
              await client.post(ApiEndpoints.dasawismaKelompok, data: data);
            }
            posted = true;
          } else if (tipe == 'kesehatan') {
            final noKk = data['no_kk'] as String?;
            // Pre-sync validation: keluarga referensi belum tersinkronkan?
            // Hanya berlaku untuk CREATE/UPDATE (POST), bukan DELETE.
            if (noKk != null && noKkKeluargaBelumSync.contains(noKk)) {
              deferred++;
              deferredItems.add('Dasawisma keluarga no_kk $noKk (menunggu keluarga tersinkronkan)');
              debugPrint('[Sync] Tunda dasawisma kesehatan no_kk $noKk: keluarga belum terkirim.');
              continue;
            }
            await client.post(ApiEndpoints.dasawismaKeluarga, data: data);
            posted = true;
          }

          if (posted) {
            await _localDB.markDasawismaSynced(id);
            record('Dasawisma', true);
          } else {
            // Tipe tidak dikenal — JANGAN tandai synced, catat kegagalan + backoff.
            debugPrint('[Sync] Dasawisma tipe tidak dikenal, dilewati: $tipe');
            await _localDB.markPendingFailed(
                'pending_dasawisma', id, 'Tipe tidak dikenal: ${tipe.isEmpty ? '(kosong)' : tipe}');
            record('Dasawisma', false,
                error: '[Dasawisma:$action] percobaan $attempt: tipe tidak dikenal ${tipe.isEmpty ? '(kosong)' : tipe}');
          }
        } catch (e) {
          debugPrint('[Sync] Gagal sync dasawisma ($action): $e');
          await _localDB.markPendingFailed('pending_dasawisma', id, _shortError(e));
          record('Dasawisma', false, error: '[Dasawisma:$action] percobaan $attempt: ${_shortError(e)}');
        }
      }

      // Sync pending anggota keluarga (hanya item yang siap dicoba ulang)
      final pendingAnggota = await _localDB.getPendingReady('pending_anggota_keluarga');
      for (final item in pendingAnggota) {
        final id = item['id'] as int;
        final action = item['action'] as String? ?? 'CREATE';
        final attempt = (item['retry_count'] as int? ?? 0) + 1;
        try {
          final data = _parseJson(item['json_data'] as String);
          final noKk = data['no_kk'] as String? ?? '';
          final nik = data['nik'] as String? ?? '';
          if (action == 'DELETE') {
            await client.delete(ApiEndpoints.keluargaAnggotaRemove(noKk, nik));
          } else {
            // Pre-sync validation: keluarga referensi belum tersinkronkan?
            // Server memvalidasi no_kk exists di tp_pkk_keluarga.
            if (noKkKeluargaBelumSync.contains(noKk)) {
              deferred++;
              deferredItems.add('Anggota keluarga no_kk $noKk (menunggu keluarga tersinkronkan)');
              debugPrint('[Sync] Tunda anggota keluarga no_kk $noKk: keluarga belum terkirim.');
              continue;
            }
            // Backend storeBulk mengharapkan array `anggota`, bukan objek
            // tunggal — sama dengan jalur online di anggota_keluarga_screen.
            await client.post(
              ApiEndpoints.keluargaAnggota(noKk),
              data: {
                'anggota': [
                  {'nik': nik}
                ]
              },
            );
          }
          await _localDB.markAnggotaKeluargaSynced(id);
          record('Anggota', true);
        } catch (e) {
          debugPrint('[Sync] Gagal sync anggota keluarga ($action): $e');
          await _localDB.markPendingFailed('pending_anggota_keluarga', id, _shortError(e));
          record('Anggota', false, error: '[Anggota:$action] percobaan $attempt: ${_shortError(e)}');
        }
      }

      // Update count
      _pendingCount = await _countPending();
    } catch (e) {
      debugPrint('[Sync] Error: $e');
    }

    _isSyncing = false;

    String message;
    if (failed > 0 && deferred > 0) {
      message = '$failed data gagal, $deferred ditunda (menunggu keluarga)';
    } else if (failed > 0) {
      message = '$failed data gagal disinkronkan';
    } else if (deferred > 0) {
      message = '$deferred data ditunda (menunggu keluarga tersinkronkan)';
    } else {
      message = 'Semua data berhasil disinkronkan';
    }

    // Catat hasil sinkronisasi ke activity log untuk audit trail.
    await ActivityService().logSync(success: success, failed: failed, deferred: deferred);

    return SyncResult(
      success,
      failed,
      message,
      lastSyncAt: DateTime.now(),
      successByType: byTypeSuccess,
      failedByType: byTypeFailed,
      failures: failures,
      deferred: deferred,
      deferredItems: deferredItems,
    );
  }

  String _shortError(Object e) {
    final s = e.toString();
    return s.length > 120 ? s.substring(0, 120) : s;
  }

  /// Salin payload tanpa field `id` — dipakai saat PUT ke endpoint detail agar
  /// body identik dengan permintaan online (id hanya ada di URL).
  Map<String, dynamic> _withoutId(Map<String, dynamic> data) {
    return Map<String, dynamic>.from(data)..remove('id');
  }

  Future<int> _countPending() async {
    final penduduk = await _localDB.getUnsyncedPenduduk();
    final keluarga = await _localDB.getUnsyncedKeluarga();
    final catatan = await _localDB.getUnsyncedCatatan();
    final dasawisma = await _localDB.getUnsyncedDasawisma();
    final anggota = await _localDB.getUnsyncedAnggotaKeluarga();
    return penduduk.length + keluarga.length + catatan.length + dasawisma.length + anggota.length;
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
  final DateTime? lastSyncAt;
  final Map<String, int> successByType;
  final Map<String, int> failedByType;
  final List<String> failures;
  final int deferred;
  final List<String> deferredItems;

  SyncResult(
    this.success,
    this.failed,
    this.message, {
    this.lastSyncAt,
    this.successByType = const {},
    this.failedByType = const {},
    this.failures = const [],
    this.deferred = 0,
    this.deferredItems = const [],
  });
}
