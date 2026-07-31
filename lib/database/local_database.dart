import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sieda_offline.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  /// Migrasi versi lama:
  /// - v1 -> v2: tambah kolom retry_count, last_error, next_retry_at untuk
  ///   mendukung retry dengan backoff pada antrian pending.
  /// - v2 -> v3: tambah kolom action di pending_dasawisma agar sinkronisasi
  ///   bisa membedakan CREATE / UPDATE / DELETE.
  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      for (final table in _pendingTables) {
        final cols = await db.rawQuery('PRAGMA table_info($table)');
        final names = cols.map((c) => c['name'] as String? ?? '').toSet();
        if (!names.contains('retry_count')) {
          await db.execute('ALTER TABLE $table ADD COLUMN retry_count INTEGER NOT NULL DEFAULT 0');
        }
        if (!names.contains('last_error')) {
          await db.execute('ALTER TABLE $table ADD COLUMN last_error TEXT');
        }
        if (!names.contains('next_retry_at')) {
          await db.execute('ALTER TABLE $table ADD COLUMN next_retry_at TEXT');
        }
      }
    }
    if (oldVersion < 3) {
      final cols = await db.rawQuery('PRAGMA table_info(pending_dasawisma)');
      final names = cols.map((c) => c['name'] as String? ?? '').toSet();
      if (!names.contains('action')) {
        await db.execute("ALTER TABLE pending_dasawisma ADD COLUMN action TEXT NOT NULL DEFAULT 'CREATE'");
      }
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS pending_anggota_keluarga (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          no_kk TEXT,
          nik TEXT,
          action TEXT NOT NULL DEFAULT 'CREATE',
          json_data TEXT NOT NULL,
          synced INTEGER DEFAULT 0,
          retry_count INTEGER NOT NULL DEFAULT 0,
          last_error TEXT,
          next_retry_at TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
  }

  /// Daftar tabel antrian pending yang memakai mekanisme retry dengan backoff.
  static const List<String> _pendingTables = [
    'pending_penduduk',
    'pending_keluarga',
    'pending_catatan',
    'pending_dasawisma',
    'pending_anggota_keluarga',
  ];

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        action TEXT NOT NULL CHECK(action IN ('CREATE','UPDATE','DELETE')),
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        status TEXT DEFAULT 'PENDING'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_penduduk (
        nik TEXT PRIMARY KEY,
        json_data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_keluarga (
        no_kk TEXT PRIMARY KEY,
        json_data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_dashboard (
        id INTEGER PRIMARY KEY DEFAULT 1,
        json_data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_penduduk (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nik TEXT,
        nama TEXT NOT NULL,
        json_data TEXT NOT NULL,
        action TEXT NOT NULL DEFAULT 'CREATE',
        synced INTEGER DEFAULT 0,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        next_retry_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_keluarga (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        no_kk TEXT,
        json_data TEXT NOT NULL,
        action TEXT NOT NULL DEFAULT 'CREATE',
        synced INTEGER DEFAULT 0,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        next_retry_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_references (
        id INTEGER PRIMARY KEY DEFAULT 1,
        json_data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_catatan (
        id INTEGER PRIMARY KEY,
        json_data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_catatan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        json_data TEXT NOT NULL,
        action TEXT NOT NULL DEFAULT 'CREATE',
        synced INTEGER DEFAULT 0,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        next_retry_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_dasawisma_kelompok (
        id INTEGER PRIMARY KEY,
        json_data TEXT NOT NULL,
        cached_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_dasawisma (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipe TEXT NOT NULL,
        action TEXT NOT NULL DEFAULT 'CREATE',
        json_data TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        next_retry_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pending_anggota_keluarga (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        no_kk TEXT,
        nik TEXT,
        action TEXT NOT NULL DEFAULT 'CREATE',
        json_data TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        next_retry_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS activity_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipe TEXT NOT NULL,
        aksi TEXT NOT NULL,
        deskripsi TEXT NOT NULL,
        detail TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ============ SYNC QUEUE ============

  Future<void> addToSyncQueue(String tableName, String action, Map<String, dynamic> payload) async {
    final db = await database;
    await db.insert('sync_queue', {
      'table_name': tableName,
      'action': action,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
      'status': 'PENDING',
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query('sync_queue', where: 'status = ?', whereArgs: ['PENDING']);
  }

  Future<void> markSyncDone(int id) async {
    final db = await database;
    await db.update('sync_queue', {'status': 'DONE'}, where: 'id = ?', whereArgs: [id]);
  }

  // ============ CACHE ============

  Future<void> cacheDashboard(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'cached_dashboard',
      {'id': 1, 'json_data': jsonEncode(data), 'cached_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedDashboard() async {
    final db = await database;
    final results = await db.query('cached_dashboard', where: 'id = ?', whereArgs: [1]);
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<void> cachePendudukList(List<Map<String, dynamic>> items) async {
    final db = await database;
    // Gabungkan per NIK (bukan hapus-total) agar cache menumpuk seluruh
    // halaman yang pernah diunduh — offline tetap bisa melihat data lengkap.
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'cached_penduduk',
        {
          'nik': item['nik'] ?? '',
          'json_data': jsonEncode(item),
          'cached_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> cacheKeluargaList(List<Map<String, dynamic>> items) async {
    final db = await database;
    // Gabungkan per No. KK agar cache menumpuk seluruh halaman yang pernah
    // diunduh — offline tetap bisa melihat data lengkap.
    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'cached_keluarga',
        {
          'no_kk': item['no_kk'] ?? '',
          'json_data': jsonEncode(item),
          'cached_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // ============ CACHED CATATAN ============

  Future<void> cacheCatatanList(List<Map<String, dynamic>> items) async {
    final db = await database;
    await db.delete('cached_catatan');
    final batch = db.batch();
    for (final item in items) {
      batch.insert('cached_catatan', {
        'id': item['id'] ?? 0,
        'json_data': jsonEncode(item),
        'cached_at': DateTime.now().toIso8601String(),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>?> getCachedCatatan() async {
    final db = await database;
    final results = await db.query('cached_catatan', orderBy: 'cached_at DESC');
    if (results.isEmpty) return null;
    return results;
  }

  /// Simpan data catatan ke antrian pending. [action] membedakan CREATE
  /// (POST baru) atau UPDATE (PUT ke detail berdasarkan id catatan).
  ///
  /// Jika id yang sama sudah punya baris pending, baris itu diperbarui
  /// (action tetap CREATE bila awalnya CREATE — dikirim sekali, data final).
  Future<int> savePendingCatatan(Map<String, dynamic> data, {String action = 'CREATE'}) async {
    final db = await database;
    final id = data['id']?.toString();
    if (id != null && id.isNotEmpty) {
      final existing = await _findUnsyncedByJson('pending_catatan', {'id': id});
      if (existing != null) {
        final keepAction = existing['action'] == 'DELETE' ? action : existing['action'];
        await db.update(
          'pending_catatan',
          {'json_data': jsonEncode(data), 'action': keepAction},
          where: 'id = ?',
          whereArgs: [existing['id']],
        );
        return existing['id'] as int;
      }
    }
    return await db.insert('pending_catatan', {
      'json_data': jsonEncode(data),
      'action': action,
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Antrikan penghapusan catatan (DELETE) untuk disinkronkan nanti.
  ///
  /// Jika masih ada baris pending untuk id yang sama, baris itu cukup
  /// dihapus (batal) — tidak ada yang perlu dikirim ke server.
  Future<void> queuePendingDeleteCatatan(int id) async {
    final db = await database;
    final existing = await _findUnsyncedByJson('pending_catatan', {'id': id.toString()});
    if (existing != null) {
      await db.delete('pending_catatan', where: 'id = ?', whereArgs: [existing['id']]);
      return;
    }
    await db.insert('pending_catatan', {
      'json_data': jsonEncode({'id': id}),
      'action': 'DELETE',
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedCatatan() async {
    final db = await database;
    return await db.query('pending_catatan', where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> markCatatanSynced(int id) async {
    final db = await database;
    await db.update('pending_catatan', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // ============ CACHED DASAWISMA ============

  Future<void> cacheDasawismaKelompok(List<Map<String, dynamic>> items) async {
    final db = await database;
    await db.delete('cached_dasawisma_kelompok');
    final batch = db.batch();
    for (final item in items) {
      batch.insert('cached_dasawisma_kelompok', {
        'id': item['id'] ?? 0,
        'json_data': jsonEncode(item),
        'cached_at': DateTime.now().toIso8601String(),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>?> getCachedDasawismaKelompok() async {
    final db = await database;
    final results = await db.query('cached_dasawisma_kelompok');
    if (results.isEmpty) return null;
    return results;
  }

  /// Simpan data dasawisma ke antrian pending. [action] membedakan CREATE
  /// (POST baru), UPDATE (PUT ke detail), atau DELETE (hapus di server).
  ///
  /// Kunci penggabungan: kelompok → `id`, kesehatan → `no_kk`. Jika entitas
  /// yang sama sudah punya baris pending, baris itu diperbarui (action tetap
  /// CREATE bila awalnya CREATE — dikirim sekali, data final).
  Future<void> savePendingDasawisma(Map<String, dynamic> data, String tipe,
      {String action = 'CREATE'}) async {
    final db = await database;
    final keys = tipe == 'kelompok'
        ? {'id': data['id']?.toString()}
        : {'no_kk': data['no_kk']?.toString()};
    if (keys.values.every((v) => v != null && v.isNotEmpty)) {
      final existing = await _findUnsyncedByJson('pending_dasawisma', keys, tipe: tipe);
      if (existing != null) {
        final keepAction = existing['action'] == 'DELETE' ? action : existing['action'];
        await db.update(
          'pending_dasawisma',
          {'json_data': jsonEncode(data), 'action': keepAction},
          where: 'id = ?',
          whereArgs: [existing['id']],
        );
        return;
      }
    }
    await db.insert('pending_dasawisma', {
      'tipe': tipe,
      'action': action,
      'json_data': jsonEncode(data),
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Antrikan penghapusan kelompok dasawisma (DELETE) untuk disinkronkan nanti.
  ///
  /// Jika masih ada baris pending untuk id yang sama, baris itu cukup
  /// dihapus (batal) — tidak ada yang perlu dikirim ke server.
  Future<void> queuePendingDeleteDasawismaKelompok(int id) async {
    final db = await database;
    final existing = await _findUnsyncedByJson(
      'pending_dasawisma',
      {'id': id.toString()},
      tipe: 'kelompok',
    );
    if (existing != null) {
      await db.delete('pending_dasawisma', where: 'id = ?', whereArgs: [existing['id']]);
      return;
    }
    await db.insert('pending_dasawisma', {
      'tipe': 'kelompok',
      'action': 'DELETE',
      'json_data': jsonEncode({'id': id}),
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Antrikan penghapusan data kesehatan keluarga dasawisma (DELETE) untuk
  /// disinkronkan nanti.
  ///
  /// Jika masih ada baris pending untuk no_kk yang sama, baris itu cukup
  /// dihapus (batal) — tidak ada yang perlu dikirim ke server.
  Future<void> queuePendingDeleteDasawismaKeluarga(String noKk) async {
    final db = await database;
    final existing = await _findUnsyncedByJson(
      'pending_dasawisma',
      {'no_kk': noKk},
      tipe: 'kesehatan',
    );
    if (existing != null) {
      await db.delete('pending_dasawisma', where: 'id = ?', whereArgs: [existing['id']]);
      return;
    }
    await db.insert('pending_dasawisma', {
      'tipe': 'kesehatan',
      'action': 'DELETE',
      'json_data': jsonEncode({'no_kk': noKk}),
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedDasawisma() async {
    final db = await database;
    return await db.query('pending_dasawisma', where: 'synced = ?', whereArgs: [0]);
  }

  /// Breakdown pending dasawisma per tipe (kelompok / kesehatan keluarga).
  Future<Map<String, int>> getPendingDasawismaByType() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT tipe, COUNT(*) as cnt FROM pending_dasawisma WHERE synced = 0 GROUP BY tipe',
    );
    final stats = <String, int>{};
    for (final row in result) {
      final tipe = row['tipe'] as String? ?? 'lainnya';
      stats[tipe] = int.tryParse(row['cnt'].toString()) ?? 0;
    }
    return stats;
  }

  Future<void> markDasawismaSynced(int id) async {
    final db = await database;
    await db.update('pending_dasawisma', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // ============ ANGGOTA KELUARGA (PENDING) ============

  /// Simpan penambahan anggota keluarga ke antrian pending (action CREATE).
  ///
  /// Jika no_kk+nik yang sama sudah punya baris pending, baris itu diperbarui
  /// dengan data terbaru (dikirim sekali, data final).
  Future<int> savePendingAnggotaKeluarga(Map<String, dynamic> data) async {
    final db = await database;
    final existing = await _findUnsyncedByJson('pending_anggota_keluarga', {
      'no_kk': data['no_kk']?.toString(),
      'nik': data['nik']?.toString(),
    });
    if (existing != null) {
      await db.update(
        'pending_anggota_keluarga',
        {'json_data': jsonEncode(data)},
        where: 'id = ?',
        whereArgs: [existing['id']],
      );
      return existing['id'] as int;
    }
    return await db.insert('pending_anggota_keluarga', {
      'no_kk': data['no_kk'],
      'nik': data['nik'],
      'json_data': jsonEncode(data),
      'action': 'CREATE',
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Antrikan penghapusan anggota keluarga (DELETE) untuk disinkronkan nanti.
  ///
  /// Jika masih ada baris pending untuk no_kk+nik yang sama, baris itu cukup
  /// dihapus (batal) — tidak ada yang perlu dikirim ke server.
  Future<void> queuePendingDeleteAnggotaKeluarga(String noKk, String nik) async {
    final db = await database;
    final existing = await _findUnsyncedByJson('pending_anggota_keluarga', {
      'no_kk': noKk,
      'nik': nik,
    });
    if (existing != null) {
      await db.delete('pending_anggota_keluarga', where: 'id = ?', whereArgs: [existing['id']]);
      return;
    }
    await db.insert('pending_anggota_keluarga', {
      'no_kk': noKk,
      'nik': nik,
      'json_data': jsonEncode({'no_kk': noKk, 'nik': nik}),
      'action': 'DELETE',
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedAnggotaKeluarga() async {
    final db = await database;
    return await db.query('pending_anggota_keluarga', where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> markAnggotaKeluargaSynced(int id) async {
    final db = await database;
    await db.update('pending_anggota_keluarga', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // ============ RETRY DENGAN BACKOFF ============

  /// Backoff eksponensial: 1 menit, 2 menit, 4 menit, ... maksimal 30 menit.
  Duration _backoffFor(int retryCount) {
    final minutes = 1 << retryCount.clamp(0, 5); // 1,2,4,8,16,32 -> cap 30
    return Duration(minutes: minutes.clamp(1, 30));
  }

  /// Catat kegagalan pengiriman untuk item pending: naikkan retry_count,
  /// simpan pesan error terakhir, dan jadwalkan percobaan berikutnya (backoff).
  Future<void> markPendingFailed(String table, int id, String error) async {
    final db = await database;
    final rows = await db.query(table, columns: ['retry_count'], where: 'id = ?', whereArgs: [id]);
    final current = rows.isNotEmpty ? (rows.first['retry_count'] as int? ?? 0) : 0;
    final next = current + 1;
    final nextRetryAt = DateTime.now().add(_backoffFor(next)).toIso8601String();
    await db.update(
      table,
      {
        'retry_count': next,
        'last_error': error,
        'next_retry_at': nextRetryAt,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Ambil item pending yang BELUM synced dan SUDAH siap dicoba (masa backoff
  /// sudah lewat). Item dengan next_retry_at NULL (belum pernah gagal) selalu siap.
  Future<List<Map<String, dynamic>>> getPendingReady(String table) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.query(
      table,
      where: 'synced = ? AND (next_retry_at IS NULL OR next_retry_at <= ?)',
      whereArgs: [0, now],
    );
  }

  /// Total item pending yang siap dicoba ulang di semua tabel antrian.
  Future<int> getPendingReadyCount() async {
    final db = await database;
    int total = 0;
    final now = DateTime.now().toIso8601String();
    for (final table in _pendingTables) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM $table WHERE synced = 0 AND (next_retry_at IS NULL OR next_retry_at <= ?)',
        [now],
      );
      total += Sqflite.firstIntValue(result) ?? 0;
    }
    return total;
  }

  /// Total item pending yang sedang dalam masa backoff (menunggu retry).
  Future<int> getPendingBackoffCount() async {
    final db = await database;
    int total = 0;
    final now = DateTime.now().toIso8601String();
    for (final table in _pendingTables) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM $table WHERE synced = 0 AND next_retry_at IS NOT NULL AND next_retry_at > ?',
        [now],
      );
      total += Sqflite.firstIntValue(result) ?? 0;
    }
    return total;
  }

  /// Hapus item pending yang sudah terkirim (synced=1) dan berusia lebih dari
  /// [maxAge] — mencegah database offline membengkak karena baris synced lama
  /// tidak pernah dibersihkan. Mengembalikan jumlah baris yang dihapus.
  ///
  /// Item yang BELUM terkirim (synced=0) TIDAK pernah dihapus.
  Future<int> cleanupOldSynced({Duration maxAge = const Duration(days: 30)}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(maxAge).toIso8601String();
    int total = 0;

    for (final table in _pendingTables) {
      final deleted = await db.delete(
        table,
        where: 'synced = ? AND created_at <= ?',
        whereArgs: [1, cutoff],
      );
      total += deleted;
    }

    // Antrian legacy sync_queue (status DONE) juga dibersihkan agar tidak
    // membengkak. Item berstatus PENDING tidak disentuh.
    final queueDeleted = await db.delete(
      'sync_queue',
      where: 'status = ? AND created_at <= ?',
      whereArgs: ['DONE', cutoff],
    );

    return total + queueDeleted;
  }

  // ============ PENDING (offline CRUD) ============

  Future<void> cacheReferences(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'cached_references',
      {'id': 1, 'json_data': jsonEncode(data), 'cached_at': DateTime.now().toIso8601String()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getCachedReferences() async {
    final db = await database;
    final results = await db.query('cached_references', where: 'id = ?', whereArgs: [1]);
    if (results.isEmpty) return null;
    return results.first;
  }

  /// Cari baris pending yang belum tersinkron pada [table] yang json_data-nya
  /// cocok dengan semua pasangan key [keys] (mis. `{'nik': nik}`). Opsional
  /// [tipe] khusus tabel pending_dasawisma (kelompok / kesehatan).
  Future<Map<String, dynamic>?> _findUnsyncedByJson(
    String table,
    Map<String, Object?> keys, {
    String? tipe,
  }) async {
    final db = await database;
    final rows = await db.query(
      table,
      where: 'synced = ?${tipe != null ? ' AND tipe = ?' : ''}',
      whereArgs: tipe != null ? [0, tipe] : [0],
    );
    for (final row in rows) {
      final json = jsonDecode(row['json_data'] as String? ?? '{}') as Map<String, dynamic>;
      var match = true;
      for (final entry in keys.entries) {
        if (json[entry.key]?.toString() != entry.value?.toString()) {
          match = false;
          break;
        }
      }
      if (match) return row;
    }
    return null;
  }

  /// Simpan data penduduk ke antrian pending. [action] membedakan CREATE
  /// (POST baru) atau UPDATE (PUT ke detail berdasarkan NIK).
  ///
  /// Jika NIK yang sama sudah punya baris pending (belum tersinkron), baris
  /// itu diperbarui dengan data terbaru — action tetap CREATE bila awalnya
  /// CREATE agar dikirim sekali sebagai data final.
  Future<int> savePendingPenduduk(Map<String, dynamic> data, {String action = 'CREATE'}) async {
    final db = await database;
    final nik = data['nik']?.toString() ?? '';
    final existing = await _findUnsyncedByJson('pending_penduduk', {'nik': nik});
    if (existing != null) {
      final keepAction = existing['action'] == 'DELETE' ? action : existing['action'];
      await db.update(
        'pending_penduduk',
        {'json_data': jsonEncode(data), 'action': keepAction},
        where: 'id = ?',
        whereArgs: [existing['id']],
      );
      return existing['id'] as int;
    }
    return await db.insert('pending_penduduk', {
      'nik': data['nik'],
      'nama': data['nama'],
      'json_data': jsonEncode(data),
      'action': action,
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Antrikan penghapusan penduduk (DELETE) untuk disinkronkan nanti.
  ///
  /// Jika masih ada baris pending untuk NIK yang sama, baris itu cukup
  /// dihapus (batal) — tidak ada yang perlu dikirim ke server.
  Future<void> queuePendingDeletePenduduk(String nik, String nama) async {
    final db = await database;
    final existing = await _findUnsyncedByJson('pending_penduduk', {'nik': nik});
    if (existing != null) {
      await db.delete('pending_penduduk', where: 'id = ?', whereArgs: [existing['id']]);
      return;
    }
    await db.insert('pending_penduduk', {
      'nik': nik,
      'nama': nama,
      'json_data': jsonEncode({'nik': nik, 'nama': nama}),
      'action': 'DELETE',
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedPenduduk() async {
    final db = await database;
    return await db.query('pending_penduduk', where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> markPendudukSynced(int id) async {
    final db = await database;
    await db.update('pending_penduduk', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  /// Simpan data keluarga ke antrian pending. [action] membedakan CREATE
  /// (POST baru) atau UPDATE (PUT ke detail berdasarkan No. KK).
  ///
  /// Jika No. KK yang sama sudah punya baris pending, baris itu diperbarui
  /// (action tetap CREATE bila awalnya CREATE — dikirim sekali, data final).
  Future<int> savePendingKeluarga(Map<String, dynamic> data, {String action = 'CREATE'}) async {
    final db = await database;
    final noKk = data['no_kk']?.toString() ?? '';
    final existing = await _findUnsyncedByJson('pending_keluarga', {'no_kk': noKk});
    if (existing != null) {
      final keepAction = existing['action'] == 'DELETE' ? action : existing['action'];
      await db.update(
        'pending_keluarga',
        {'json_data': jsonEncode(data), 'action': keepAction},
        where: 'id = ?',
        whereArgs: [existing['id']],
      );
      return existing['id'] as int;
    }
    return await db.insert('pending_keluarga', {
      'no_kk': data['no_kk'],
      'json_data': jsonEncode(data),
      'action': action,
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Antrikan penghapusan keluarga (DELETE) untuk disinkronkan nanti.
  ///
  /// Jika masih ada baris pending untuk No. KK yang sama, baris itu cukup
  /// dihapus (batal) — tidak ada yang perlu dikirim ke server.
  Future<void> queuePendingDeleteKeluarga(String noKk) async {
    final db = await database;
    final existing = await _findUnsyncedByJson('pending_keluarga', {'no_kk': noKk});
    if (existing != null) {
      await db.delete('pending_keluarga', where: 'id = ?', whereArgs: [existing['id']]);
      return;
    }
    await db.insert('pending_keluarga', {
      'no_kk': noKk,
      'json_data': jsonEncode({'no_kk': noKk}),
      'action': 'DELETE',
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedKeluarga() async {
    final db = await database;
    return await db.query('pending_keluarga', where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> markKeluargaSynced(int id) async {
    final db = await database;
    await db.update('pending_keluarga', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // ============ STATISTIK DATABASE ============

  /// Key SharedPreferences untuk penanda waktu pembersihan otomatis terakhir.
  static const lastCleanupAtKey = 'last_cleanup_at';

  /// Key SharedPreferences untuk jumlah item yang dihapus pada pembersihan
  /// otomatis terakhir.
  static const lastCleanupDeletedKey = 'last_cleanup_deleted';

  /// Total ukuran file database offline (db + wal + shm) dalam byte.
  /// Dipakai untuk statistik penyimpanan di halaman admin.
  Future<int> getDatabaseSizeBytes() async {
    try {
      final dbPath = await getDatabasesPath();
      final base = join(dbPath, 'sieda_offline.db');
      int total = 0;
      for (final suffix in ['', '-wal', '-shm']) {
        final file = File(base + suffix);
        if (await file.exists()) {
          total += await file.length();
        }
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Statistik pembersihan otomatis terakhir: jumlah item yang dihapus dan
  /// kapan terakhir kali berjalan (disimpan oleh main() ke SharedPreferences).
  Future<({int deleted, String? at})> getLastCleanupStats() async {
    final prefs = await SharedPreferences.getInstance();
    final deleted = prefs.getInt(lastCleanupDeletedKey) ?? 0;
    final at = prefs.getString(lastCleanupAtKey);
    return (deleted: deleted, at: at);
  }

  // ============ ADMIN / MAINTENANCE ============

  /// Get count of items in all cache tables.
  Future<Map<String, int>> getCacheStats() async {
    final db = await database;
    final tables = ['cached_penduduk', 'cached_keluarga', 'cached_dashboard', 'cached_references', 'cached_catatan', 'cached_dasawisma_kelompok'];
    final stats = <String, int>{};
    for (final table in tables) {
      final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM $table');
      stats[table] = Sqflite.firstIntValue(result) ?? 0;
    }
    return stats;
  }

  /// Get detailed pending sync counts per type.
  Future<Map<String, int>> getPendingStats() async {
    final db = await database;
    final tables = {
      'pending_penduduk': 'Penduduk',
      'pending_keluarga': 'Keluarga',
      'pending_catatan': 'Catatan',
      'pending_dasawisma': 'Dasawisma',
      'pending_anggota_keluarga': 'Anggota',
    };
    final stats = <String, int>{};
    for (final entry in tables.entries) {
      final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM ${entry.key} WHERE synced = 0');
      final count = Sqflite.firstIntValue(result) ?? 0;
      stats[entry.value] = count;
    }
    return stats;
  }

  /// Clear all cached data (keep pending queues intact).
  Future<void> clearAllCache() async {
    final db = await database;
    await db.delete('cached_penduduk');
    await db.delete('cached_keluarga');
    await db.delete('cached_dashboard');
    await db.delete('cached_references');
    await db.delete('cached_catatan');
    await db.delete('cached_dasawisma_kelompok');
  }

  /// Clear all pending sync queues (data yang belum terkirim akan hilang).
  Future<void> clearAllPending() async {
    final db = await database;
    await db.delete('pending_penduduk');
    await db.delete('pending_keluarga');
    await db.delete('pending_catatan');
    await db.delete('pending_dasawisma');
    await db.delete('sync_queue');
  }

  /// Full reset: clear cache AND pending data. Log aktivitas tetap disimpan.
  Future<void> resetAllData() async {
    await clearAllCache();
    await clearAllPending();
  }

  // ============ ACTIVITY LOG ============

  /// Add a new activity log entry.
  Future<void> addActivityLog({
    required String tipe,
    required String aksi,
    required String deskripsi,
    String? detail,
  }) async {
    final db = await database;
    await db.insert('activity_log', {
      'tipe': tipe,
      'aksi': aksi,
      'deskripsi': deskripsi,
      'detail': detail ?? '',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get all activity logs, newest first.
  Future<List<Map<String, dynamic>>> getActivityLogs({int limit = 50}) async {
    final db = await database;
    return await db.query('activity_log', orderBy: 'created_at DESC', limit: limit);
  }

  /// Get activity logs filtered by type.
  Future<List<Map<String, dynamic>>> getActivityLogsByType(String tipe, {int limit = 50}) async {
    final db = await database;
    return await db.query(
      'activity_log',
      where: 'tipe = ?',
      whereArgs: [tipe],
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  /// Get activity logs count.
  Future<int> getActivityLogCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM activity_log');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Clear all activity logs.
  Future<void> clearActivityLogs() async {
    final db = await database;
    await db.delete('activity_log');
  }

  /// Get total number of records across all pending tables.
  Future<int> getTotalPendingCount() async {
    final stats = await getPendingStats();
    int total = 0;
    for (final count in stats.values) {
      total += count;
    }
    return total;
  }

  /// Get total number of cached records.
  Future<int> getTotalCacheCount() async {
    final stats = await getCacheStats();
    int total = 0;
    for (final count in stats.values) {
      total += count;
    }
    return total;
  }

  // ============ DATA INTEGRITY CHECK ============

  /// Run integrity checks on offline data.
  /// Returns a map with issues found.
  Future<IntegrityResult> checkDataIntegrity() async {
    final result = IntegrityResult();

    // 1. Check duplicate NIK in pending_penduduk
    final pendingPenduduk = await getUnsyncedPenduduk();
    final nikSet = <String, int>{};
    for (final item in pendingPenduduk) {
      final nik = item['nik'] as String?;
      if (nik != null && nik.isNotEmpty) {
        nikSet[nik] = (nikSet[nik] ?? 0) + 1;
      }
    }
    for (final entry in nikSet.entries) {
      if (entry.value > 1) {
        result.addIssue(
          tipe: 'Penduduk',
          severity: IntegritySeverity.error,
          judul: 'Duplikat NIK: ${entry.key}',
          detail: 'NIK ${entry.key} muncul ${entry.value} kali di data pending.',
        );
      }
    }

    // 2. Check duplicate No.KK in pending_keluarga
    final pendingKeluarga = await getUnsyncedKeluarga();
    final kkSet = <String, int>{};
    for (final item in pendingKeluarga) {
      final noKk = item['no_kk'] as String?;
      if (noKk != null && noKk.isNotEmpty) {
        kkSet[noKk] = (kkSet[noKk] ?? 0) + 1;
      }
    }
    for (final entry in kkSet.entries) {
      if (entry.value > 1) {
        result.addIssue(
          tipe: 'Keluarga',
          severity: IntegritySeverity.error,
          judul: 'Duplikat No. KK: ${entry.key}',
          detail: 'No. KK ${entry.key} muncul ${entry.value} kali di data pending.',
        );
      }
    }

    // 3. Validate NIK relations: id_kepala_keluarga in pending_keluarga
    //    should exist as nik in pending_penduduk OR cached_penduduk
    if (pendingKeluarga.isNotEmpty) {
      // Build set of ALL known NIKs: pending + cached
      final allNik = <String>{};

      // Add NIKs from pending penduduk
      for (final item in pendingPenduduk) {
        final nik = item['nik'] as String?;
        if (nik != null && nik.isNotEmpty) allNik.add(nik);
      }

      // Add NIKs from cached penduduk too
      final cachedPenduduk = await getCachedPendudukList();
      for (final item in cachedPenduduk) {
        try {
          final jsonData = jsonDecode(item['json_data'] as String) as Map<String, dynamic>;
          final nik = jsonData['nik'] as String?;
          if (nik != null && nik.isNotEmpty) allNik.add(nik);
        } catch (_) {}
      }

      for (final item in pendingKeluarga) {
        try {
          final jsonData = jsonDecode(item['json_data'] as String) as Map<String, dynamic>;
          final kepalaNik = jsonData['id_kepala_keluarga'] as String?;
          if (kepalaNik != null && kepalaNik.isNotEmpty && !allNik.contains(kepalaNik)) {
            result.addIssue(
              tipe: 'Relasi',
              severity: IntegritySeverity.warning,
              judul: 'Kepala keluarga NIK $kepalaNik tidak ditemukan',
              detail: 'No. KK ${item['no_kk']} merujuk ke NIK $kepalaNik yang belum ada di data penduduk (pending atau cache).',
            );
          }
        } catch (_) {}
      }
    }

    // 4. Check for empty NIK in pending_penduduk
    for (final item in pendingPenduduk) {
      final nik = item['nik'] as String?;
      if (nik == null || nik.isEmpty) {
        result.addIssue(
          tipe: 'Penduduk',
          severity: IntegritySeverity.error,
          judul: 'Data pending tanpa NIK',
          detail: 'ID ${item['id']}: Data penduduk tanpa NIK ditemukan di antrian pending.',
        );
      }
    }

    // 5. Validate NIK relations in pending_catatan:
    //    id_warga_ibu (required) and id_warga_suami (optional)
    //    should exist in pending_penduduk OR cached_penduduk
    final pendingCatatan = await getUnsyncedCatatan();
    if (pendingCatatan.isNotEmpty) {
      // Build set of ALL known NIKs: pending + cached
      final allNik = <String>{};

      for (final item in pendingPenduduk) {
        final nik = item['nik'] as String?;
        if (nik != null && nik.isNotEmpty) allNik.add(nik);
      }

      final cachedPenduduk = await getCachedPendudukList();
      for (final item in cachedPenduduk) {
        try {
          final jsonData = jsonDecode(item['json_data'] as String) as Map<String, dynamic>;
          final nik = jsonData['nik'] as String?;
          if (nik != null && nik.isNotEmpty) allNik.add(nik);
        } catch (_) {}
      }

      for (final item in pendingCatatan) {
        try {
          final jsonData = jsonDecode(item['json_data'] as String) as Map<String, dynamic>;

          // Check id_warga_ibu (wajib ada)
          final nikIbu = jsonData['id_warga_ibu'] as String?;
          if (nikIbu != null && nikIbu.isNotEmpty && !allNik.contains(nikIbu)) {
            result.addIssue(
              tipe: 'Catatan',
              severity: IntegritySeverity.error,
              judul: 'NIK Ibu $nikIbu tidak ditemukan',
              detail: 'Catatan ID ${item['id']} merujuk ke NIK ibu $nikIbu yang belum ada di data penduduk (pending atau cache).',
            );
          }

          // Check id_warga_suami (opsional)
          final nikSuami = jsonData['id_warga_suami'] as String?;
          if (nikSuami != null && nikSuami.isNotEmpty && !allNik.contains(nikSuami)) {
            result.addIssue(
              tipe: 'Catatan',
              severity: IntegritySeverity.warning,
              judul: 'NIK Suami $nikSuami tidak ditemukan',
              detail: 'Catatan ID ${item['id']} merujuk ke NIK suami $nikSuami yang belum ada di data penduduk (pending atau cache).',
            );
          }
        } catch (_) {}
      }
    }

    return result;
  }

  /// Get all cached penduduk entries (raw).
  Future<List<Map<String, dynamic>>> getCachedPendudukList() async {
    final db = await database;
    return await db.query('cached_penduduk');
  }

  /// Get all cached keluarga entries (raw).
  Future<List<Map<String, dynamic>>> getCachedKeluargaList() async {
    final db = await database;
    return await db.query('cached_keluarga');
  }
}

// ============ DATA INTEGRITY TYPES ============

enum IntegritySeverity { info, warning, error }

class IntegrityIssue {
  final String tipe;
  final IntegritySeverity severity;
  final String judul;
  final String detail;

  IntegrityIssue({
    required this.tipe,
    required this.severity,
    required this.judul,
    required this.detail,
  });
}

class IntegrityResult {
  final List<IntegrityIssue> issues = [];

  void addIssue({
    required String tipe,
    required IntegritySeverity severity,
    required String judul,
    required String detail,
  }) {
    issues.add(IntegrityIssue(
      tipe: tipe,
      severity: severity,
      judul: judul,
      detail: detail,
    ));
  }

  int get totalCount => issues.length;
  int get errorCount => issues.where((i) => i.severity == IntegritySeverity.error).length;
  int get warningCount => issues.where((i) => i.severity == IntegritySeverity.warning).length;
  int get infoCount => issues.where((i) => i.severity == IntegritySeverity.info).length;

  bool get hasIssues => issues.isNotEmpty;
  bool get hasErrors => errorCount > 0;
  String get statusLabel {
    if (!hasIssues) return 'Tidak ada masalah';
    if (hasErrors) return '$errorCount error, $warningCount warning';
    if (warningCount > 0) return '$warningCount warning';
    return '$infoCount info';
  }
}
