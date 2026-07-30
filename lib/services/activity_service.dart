import '../database/local_database.dart';

/// Service for logging user activities related to offline data.
/// Setiap kali user menambah/mengedit data secara online atau offline,
/// aktivitas tersebut dicatat ke dalam tabel activity_log lokal untuk audit trail.
class ActivityService {
  final LocalDatabase _db = LocalDatabase();

  /// Log a new activity.
  ///
  /// [tipe] — kategori data: 'Penduduk', 'Keluarga', 'Catatan', 'Dasawisma'
  /// [aksi] — tindakan: 'Tambah', 'Ubah', 'Hapus', 'Sync', 'Hapus Cache'
  /// [deskripsi] — deskripsi singkat yang bisa dibaca user
  /// [detail] — info tambahan opsional (misal: NIK, No.KK, jumlah data)
  Future<void> log({
    required String tipe,
    required String aksi,
    required String deskripsi,
    String? detail,
  }) async {
    try {
      await _db.addActivityLog(
        tipe: tipe,
        aksi: aksi,
        deskripsi: deskripsi,
        detail: detail,
      );
    } catch (e) {
      // Logging failure should never crash the app
    }
  }

  /// Convenience: log a successful save (online or offline).
  Future<void> logSave({
    required String tipe,
    required String nama,
    String? identifier,
    bool isEdit = false,
    bool isOnline = true,
  }) async {
    final aksi = isEdit ? 'Ubah' : 'Tambah';
    final mode = isOnline ? 'Online' : 'Offline';
    final desc = '$mode: $nama';
    final detail = identifier != null ? '$identifier | $mode' : mode;
    await log(tipe: tipe, aksi: aksi, deskripsi: desc, detail: detail);
  }

  /// Convenience: log a delete.
  Future<void> logDelete({
    required String tipe,
    required String nama,
    String? identifier,
  }) async {
    await log(
      tipe: tipe,
      aksi: 'Hapus',
      deskripsi: nama,
      detail: identifier,
    );
  }

  /// Convenience: log a sync operation.
  Future<void> logSync({
    required int success,
    required int failed,
  }) async {
    await log(
      tipe: 'Sistem',
      aksi: 'Sync',
      deskripsi: success > 0
          ? '$success data berhasil disinkronkan'
          : 'Sinkronisasi selesai',
      detail: failed > 0
          ? '$success berhasil, $failed gagal'
          : '$success berhasil',
    );
  }

  /// Convenience: log cache/pending clear.
  Future<void> logMaintenance({
    required String aksi,
    required String deskripsi,
    String? detail,
  }) async {
    await log(
      tipe: 'Sistem',
      aksi: aksi,
      deskripsi: deskripsi,
      detail: detail,
    );
  }
}
