import 'dart:convert';
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
      version: 1,
      onCreate: _createTables,
    );
  }

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
        json_data TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_weather (
        location_key TEXT PRIMARY KEY,
        json_data TEXT NOT NULL,
        cached_at TEXT NOT NULL
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
    await db.delete('cached_penduduk');
    final batch = db.batch();
    for (final item in items) {
      batch.insert('cached_penduduk', {
        'nik': item['nik'] ?? '',
        'json_data': jsonEncode(item),
        'cached_at': DateTime.now().toIso8601String(),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> cacheKeluargaList(List<Map<String, dynamic>> items) async {
    final db = await database;
    await db.delete('cached_keluarga');
    final batch = db.batch();
    for (final item in items) {
      batch.insert('cached_keluarga', {
        'no_kk': item['no_kk'] ?? '',
        'json_data': jsonEncode(item),
        'cached_at': DateTime.now().toIso8601String(),
      });
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

  Future<int> savePendingCatatan(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('pending_catatan', {
      'json_data': jsonEncode(data),
      'action': 'CREATE',
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

  Future<void> savePendingDasawisma(Map<String, dynamic> data, String tipe) async {
    final db = await database;
    await db.insert('pending_dasawisma', {
      'tipe': tipe,
      'json_data': jsonEncode(data),
      'synced': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getUnsyncedDasawisma() async {
    final db = await database;
    return await db.query('pending_dasawisma', where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> markDasawismaSynced(int id) async {
    final db = await database;
    await db.update('pending_dasawisma', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
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

  Future<int> savePendingPenduduk(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('pending_penduduk', {
      'nik': data['nik'],
      'nama': data['nama'],
      'json_data': jsonEncode(data),
      'action': 'CREATE',
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

  Future<int> savePendingKeluarga(Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert('pending_keluarga', {
      'no_kk': data['no_kk'],
      'json_data': jsonEncode(data),
      'action': 'CREATE',
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

  // ============ WEATHER CACHE ============

  /// Cache weather data for a location.
  Future<void> cacheWeather(Map<String, dynamic> data, String locationKey) async {
    final db = await database;
    await db.insert(
      'cached_weather',
      {
        'location_key': locationKey,
        'json_data': jsonEncode(data),
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get cached weather data for a location.
  Future<Map<String, dynamic>?> getCachedWeather(String locationKey) async {
    final db = await database;
    final results = await db.query(
      'cached_weather',
      where: 'location_key = ?',
      whereArgs: [locationKey],
    );
    if (results.isEmpty) return null;
    return results.first;
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
