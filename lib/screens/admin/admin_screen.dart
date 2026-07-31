import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../database/local_database.dart';
import '../../services/connectivity_service.dart';
import '../../services/sync_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _localDB = LocalDatabase();
  Map<String, int> _cacheStats = {};
  Map<String, int> _pendingStats = {};
  Map<String, int> _dasawismaPendingByType = {};
  int _totalCache = 0;
  int _totalPending = 0;
  int _backoffCount = 0;
  int _dbSizeBytes = 0;
  int _lastCleanupDeleted = 0;
  DateTime? _lastCleanupAt;
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _lastSyncMessage;
  DateTime? _lastSyncAt;
  SyncResult? _lastSyncResult;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final cacheStats = await _localDB.getCacheStats();
      final pendingStats = await _localDB.getPendingStats();
      final dasawismaByType = await _localDB.getPendingDasawismaByType();
      final totalCache = await _localDB.getTotalCacheCount();
      final totalPending = await _localDB.getTotalPendingCount();
      final backoffCount = await _localDB.getPendingBackoffCount();
      final dbSizeBytes = await _localDB.getDatabaseSizeBytes();
      final cleanupStats = await _localDB.getLastCleanupStats();
      await _loadActivityLogs();
      if (mounted) {
        setState(() {
          _cacheStats = cacheStats;
          _pendingStats = pendingStats;
          _dasawismaPendingByType = dasawismaByType;
          _totalCache = totalCache;
          _totalPending = totalPending;
          _backoffCount = backoffCount;
          _dbSizeBytes = dbSizeBytes;
          _lastCleanupDeleted = cleanupStats.deleted;
          _lastCleanupAt = DateTime.tryParse(cleanupStats.at ?? '');
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _syncPending() async {
    final connectivity = context.read<ConnectivityService>();
    if (!connectivity.isOnline) {
      _showSnackbar('Tidak ada koneksi internet.', AppTheme.warning);
      return;
    }

    setState(() => _isSyncing = true);
    final syncService = SyncService(connectivity);
    final result = await syncService.syncAll();
    await _loadStats();
    if (mounted) {
      setState(() {
        _isSyncing = false;
        _lastSyncMessage = result.message;
        _lastSyncAt = result.lastSyncAt;
        _lastSyncResult = result;
      });
      _showSnackbar(result.message, result.failed > 0 ? AppTheme.warning : AppTheme.success);
    }
  }

  Future<void> _confirmClearCache() async {
    if (_totalCache == 0) {
      _showSnackbar('Tidak ada cache untuk dihapus.', AppTheme.textHintOf(context));
      return;
    }

    final confirmed = await _showConfirmDialog(
      'Hapus Cache',
      'Semua data cache (penduduk, keluarga, dashboard, referensi) akan dihapus. Data pending sinkronisasi tidak terpengaruh. Lanjutkan?',
    );
    if (confirmed != true) return;

    await _localDB.clearAllCache();
    await _loadStats();
    if (mounted) _showSnackbar('Cache berhasil dihapus.', AppTheme.success);
  }

  Future<void> _confirmClearPending() async {
    if (_totalPending == 0) {
      _showSnackbar('Tidak ada data pending.', AppTheme.textHintOf(context));
      return;
    }

    final confirmed = await _showConfirmDialog(
      'Hapus Data Pending',
      'Semua data yang belum tersinkronisasi akan dihapus permanen. Data ini tidak bisa dikirim lagi ke server. Lanjutkan?',
      isDanger: true,
    );
    if (confirmed != true) return;

    await _localDB.clearAllPending();
    await _loadStats();
    if (mounted) _showSnackbar('Data pending berhasil dihapus.', AppTheme.success);
  }

  Future<void> _confirmResetAll() async {
    final confirmed = await _showConfirmDialog(
      'Reset Semua Data Offline',
      'SEMUA data offline akan dihapus: cache dan data pending yang belum dikirim. Data di server TIDAK terpengaruh. Lanjutkan?',
      isDanger: true,
    );
    if (confirmed != true) return;

    await _localDB.resetAllData();
    await _loadStats();
    if (mounted) _showSnackbar('Semua data offline berhasil direset.', AppTheme.success);
  }

  Future<bool?> _showConfirmDialog(String title, String content, {bool isDanger = false}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(isDanger ? Icons.warning_rounded : Icons.info_outline_rounded,
                color: isDanger ? AppTheme.error : AppTheme.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Text(content, style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryOf(ctx))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? AppTheme.error : AppTheme.primary,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isDanger ? 'Hapus' : 'Ya', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            color == AppTheme.success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: Colors.white, size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Offline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _loadStats,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isLoading)
                const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else ...[
                // ============ SECTION 1: STATUS SINKRONISASI ============
                _sectionHeader('Status Sinkronisasi'),
                const SizedBox(height: 12),
                _buildSyncStatusCard(),
                const SizedBox(height: 24),

                // ============ SECTION 2: STATISTIK DATABASE ============
                _sectionHeader('Statistik Database'),
                const SizedBox(height: 12),
                _buildDatabaseStatsSection(),
                const SizedBox(height: 24),

                // ============ SECTION 3: RINCIAN PENDING ============
                _sectionHeader('Data Pending per Tipe'),
                const SizedBox(height: 12),
                _buildPendingDetails(),
                const SizedBox(height: 24),

                // ============ SECTION 3: CACHE ============
                _sectionHeader('Cache Tersimpan'),
                const SizedBox(height: 12),
                _buildCacheSection(),
                const SizedBox(height: 24),

                // ============ SECTION 4: INTEGRITY CHECK ============
                _sectionHeader('Integritas Data'),
                const SizedBox(height: 12),
                _buildIntegritySection(),
                const SizedBox(height: 24),

                // ============ SECTION 5: ACTIVITY LOG ============
                _sectionHeader('Log Aktivitas'),
                const SizedBox(height: 12),
                _buildActivityLogSection(context),
                const SizedBox(height: 24),

                // ============ SECTION 5: RESET & MAINTENANCE ============
                _sectionHeader('Maintenance'),
                const SizedBox(height: 12),
                _buildMaintenanceSection(),
              ],

              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Data di server tidak terpengaruh oleh perubahan di halaman ini.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(width: 3, height: 16,
            decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  // ==================== SYNC STATUS CARD ====================

  Widget _buildSyncStatusCard() {
    final isOnline = context.watch<ConnectivityService>().isOnline;
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status bar
          Row(
            children: [
              // Online/offline badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isOnline ? AppTheme.success : AppTheme.warning).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? AppTheme.success : AppTheme.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: isOnline ? AppTheme.success : AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '$_totalPending menunggu',
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: _totalPending > 0 ? AppTheme.warning : AppTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar visual
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _totalPending > 0 ? 0.15 : 1.0,
              minHeight: 6,
              backgroundColor: AppTheme.borderOf(context),
              valueColor: AlwaysStoppedAnimation<Color>(
                _totalPending > 0 ? AppTheme.warning : AppTheme.success,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _totalPending > 0
                ? '$_totalPending data belum dikirim ke server'
                : 'Semua data sudah tersinkronisasi',
            style: TextStyle(fontSize: 11, color: _totalPending > 0 ? AppTheme.warning : AppTheme.success),
          ),
          if (_backoffCount > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 13, color: AppTheme.info),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '$_backoffCount data menunggu retry otomatis (backoff)',
                    style: TextStyle(fontSize: 11, color: AppTheme.info),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),

          if (_lastSyncMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _lastSyncMessage!,
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context), fontStyle: FontStyle.italic),
              ),
            ),

          if (_lastSyncAt != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 13, color: AppTheme.textHintOf(context)),
                  const SizedBox(width: 4),
                  Text(
                    'Terakhir: ${_formatTimestamp(_lastSyncAt!.toIso8601String())}',
                    style: TextStyle(fontSize: 11, color: AppTheme.textHintOf(context)),
                  ),
                ],
              ),
            ),

          // Per-type result dari sinkronisasi terakhir
          if (_lastSyncResult != null && (_lastSyncResult!.success > 0 || _lastSyncResult!.failed > 0))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ...(_lastSyncResult!.successByType.entries.map((e) => _typeResultChip(e.key, e.value, isSuccess: true))),
                  ...(_lastSyncResult!.failedByType.entries.map((e) => _typeResultChip(e.key, e.value, isSuccess: false))),
                ],
              ),
            ),

          // Rincian data yang ditunda (menunggu keluarga tersinkronkan)
          if (_lastSyncResult != null && _lastSyncResult!.deferred > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.info.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_lastSyncResult!.deferred} data ditunda (menunggu keluarga tersinkronkan):',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.info),
                    ),
                    const SizedBox(height: 4),
                    ..._lastSyncResult!.deferredItems.take(3).map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '- $d',
                            style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryOf(context)),
                          ),
                        )),
                    if (_lastSyncResult!.deferredItems.length > 3)
                      Text(
                        'dan ${_lastSyncResult!.deferredItems.length - 3} lainnya...',
                        style: TextStyle(fontSize: 10, color: AppTheme.textHintOf(context), fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            ),

          // Rincian kegagalan terakhir
          if (_lastSyncResult != null && _lastSyncResult!.failures.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_lastSyncResult!.failures.length} data gagal terkirim:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.error),
                    ),
                    const SizedBox(height: 4),
                    ..._lastSyncResult!.failures.take(3).map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '- $f',
                            style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryOf(context)),
                          ),
                        )),
                    if (_lastSyncResult!.failures.length > 3)
                      Text(
                        'dan ${_lastSyncResult!.failures.length - 3} lainnya...',
                        style: TextStyle(fontSize: 10, color: AppTheme.textHintOf(context), fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
              ),
            ),

          // Sync button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_isSyncing || !isOnline || _totalPending == 0) ? null : _syncPending,
              icon: _isSyncing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync_rounded, size: 18),
              label: Text(_isSyncing ? 'Menyinkronkan...' : 'Sinkronkan Sekarang'),
            ),
          ),
        ],
      ),
      ),
    );
  }

  // ==================== DATABASE STATS SECTION ====================

  Widget _buildDatabaseStatsSection() {
    final cs = Theme.of(context).colorScheme;
    final typeLabels = {
      'Penduduk': (Icons.people_outline_rounded, AppTheme.primary),
      'Keluarga': (Icons.family_restroom_outlined, AppTheme.info),
      'Catatan': (Icons.baby_changing_station_rounded, AppTheme.female),
      'Dasawisma': (Icons.groups_outlined, AppTheme.success),
      'Anggota': (Icons.group_add_outlined, AppTheme.warning),
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ukuran database
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storage_rounded, size: 18, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text('Ukuran Database', style: const TextStyle(fontSize: 13))),
                Text(
                  _formatBytes(_dbSizeBytes),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Total baris pending per tipe
            Text('Baris Pending per Tipe',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryOf(context))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: typeLabels.entries.map((entry) {
                final count = _pendingStats[entry.key] ?? 0;
                final (icon, color) = entry.value;
                final active = count > 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (active ? color : AppTheme.textHintOf(context)).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: active ? color : AppTheme.textHintOf(context)),
                      const SizedBox(width: 6),
                      Text(
                        '${entry.key}: $count',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active ? color : AppTheme.textHintOf(context),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Info cleanup terakhir
            Row(
              children: [
                Icon(Icons.cleaning_services_rounded, size: 16, color: AppTheme.info),
                const SizedBox(width: 8),
                Expanded(child: Text('Cleanup Terakhir', style: const TextStyle(fontSize: 13))),
                Text(
                  _lastCleanupAt != null
                      ? _formatTimestamp(_lastCleanupAt!.toIso8601String())
                      : 'Belum pernah',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.info.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.info.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    _lastCleanupDeleted > 0 ? Icons.delete_rounded : Icons.check_circle_outline_rounded,
                    size: 16,
                    color: _lastCleanupDeleted > 0 ? AppTheme.info : AppTheme.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastCleanupAt == null
                          ? 'Pembersihan otomatis akan berjalan saat aplikasi dibuka (menghapus data synced berusia > 30 hari).'
                          : '$_lastCleanupDeleted item synced lama dihapus pada pembersihan terakhir.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const kb = 1024;
    const mb = kb * 1024;
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(2)} MB';
    if (bytes >= kb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    return '$bytes B';
  }

  // ==================== PENDING DETAILS ====================

  Widget _buildPendingDetails() {
    final labels = {
      'Penduduk': Icons.people_outline_rounded,
      'Keluarga': Icons.family_restroom_outlined,
      'Catatan': Icons.baby_changing_station_rounded,
      'Dasawisma': Icons.groups_outlined,
      'Anggota': Icons.group_add_outlined,
    };

    final colors = {
      'Penduduk': AppTheme.primary,
      'Keluarga': AppTheme.info,
      'Catatan': AppTheme.female,
      'Dasawisma': AppTheme.success,
      'Anggota': AppTheme.warning,
    };

    final hasData = _pendingStats.values.any((c) => c > 0);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: hasData
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._pendingStats.entries.map((entry) {
                  final label = entry.key;
                  final count = entry.value;
                  final icon = labels[label] ?? Icons.pending_rounded;
                  final color = colors[label] ?? AppTheme.textHintOf(context);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, size: 18, color: color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: count > 0 ? AppTheme.warning.withValues(alpha: 0.15) : AppTheme.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: count > 0 ? AppTheme.warning : AppTheme.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Breakdown dasawisma per tipe (kelompok / kesehatan keluarga)
                        if (label == 'Dasawisma' && count > 0) ...[
                          Padding(
                            padding: const EdgeInsets.only(left: 38, top: 4),
                            child: Row(
                              children: [
                                Icon(Icons.subdirectory_arrow_right_rounded, size: 14, color: AppTheme.textHintOf(context)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Kelompok',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context)),
                                  ),
                                ),
                                _dasawismaCountChip('kelompok'),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Kesehatan Keluarga',
                                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context)),
                                  ),
                                ),
                                _dasawismaCountChip('kesehatan'),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_done_rounded, size: 20, color: AppTheme.success),
                    const SizedBox(width: 8),
                    Text('Tidak ada data pending', style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 13)),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _typeResultChip(String type, int count, {required bool isSuccess}) {
    final color = isSuccess ? AppTheme.success : AppTheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$type: $count ${isSuccess ? 'ok' : 'gagal'}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _dasawismaCountChip(String tipe) {
    final count = _dasawismaPendingByType[tipe] ?? 0;
    final active = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: active ? AppTheme.success.withValues(alpha: 0.12) : AppTheme.textHintOf(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: active ? AppTheme.success : AppTheme.textHintOf(context),
        ),
      ),
    );
  }

  // ==================== CACHE SECTION ====================

  Widget _buildCacheSection() {
    final labels = {
      'cached_penduduk': 'Penduduk',
      'cached_keluarga': 'Keluarga',
      'cached_dashboard': 'Dashboard',
      'cached_references': 'Referensi',
      'cached_catatan': 'Catatan',
      'cached_dasawisma_kelompok': 'Dasawisma',
    };

    final icons = {
      'cached_penduduk': Icons.people_outline_rounded,
      'cached_keluarga': Icons.family_restroom_outlined,
      'cached_dashboard': Icons.dashboard_rounded,
      'cached_references': Icons.list_alt_rounded,
      'cached_catatan': Icons.baby_changing_station_rounded,
      'cached_dasawisma_kelompok': Icons.groups_outlined,
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ..._cacheStats.entries.map((entry) {
            final key = entry.key;
            final count = entry.value;
            final label = labels[key] ?? key;
            final icon = icons[key] ?? Icons.storage_rounded;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: AppTheme.textHintOf(context)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context)))),
                  Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
          const Divider(height: 16),
          Row(
            children: [
              Icon(Icons.storage_rounded, size: 16, color: AppTheme.textPrimaryOf(context)),
              const SizedBox(width: 8),
              const Text('Total Cache', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('$_totalCache entri', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary)),
            ],
          ),
          if (_totalCache > 0) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _confirmClearCache,
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Hapus Semua Cache'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }

  // ==================== MAINTENANCE SECTION ====================

  // ==================== INTEGRITY CHECK SECTION ====================

  Future<void> _runIntegrityCheck() async {
    setState(() => _isCheckingIntegrity = true);
    try {
      final result = await _localDB.checkDataIntegrity();
      if (mounted) {
        setState(() {
          _integrityResult = result;
          _isCheckingIntegrity = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingIntegrity = false);
        _showSnackbar('Gagal memeriksa integritas data.', AppTheme.error);
      }
    }
  }

  Widget _buildIntegritySection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Run check button + status
          if (_integrityResult == null && !_isCheckingIntegrity)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _runIntegrityCheck,
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('Jalankan Pemeriksaan'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          else if (_isCheckingIntegrity)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const CircularProgressIndicator(strokeWidth: 2.5),
                    const SizedBox(height: 12),
                    Text('Memeriksa data offline...',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryOf(context))),
                  ],
                ),
              ),
            )
          else ...[
            // Result summary
            Row(
              children: [
                Icon(
                  _integrityResult!.hasErrors
                      ? Icons.cancel_rounded
                      : _integrityResult!.hasIssues
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_rounded,
                  size: 20,
                  color: _integrityResult!.hasErrors
                      ? AppTheme.error
                      : _integrityResult!.hasIssues
                          ? AppTheme.warning
                          : AppTheme.success,
                ),
                const SizedBox(width: 8),
                Text(
                  _integrityResult!.statusLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _integrityResult!.hasErrors
                        ? AppTheme.error
                        : _integrityResult!.hasIssues
                            ? AppTheme.warning
                            : AppTheme.success,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _runIntegrityCheck,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded, size: 12, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text('Ulang', style: TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_integrityResult!.hasIssues) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              // Issues list
              ..._integrityResult!.issues.map((issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          issue.severity == IntegritySeverity.error
                              ? Icons.error_outline_rounded
                              : issue.severity == IntegritySeverity.warning
                                  ? Icons.warning_amber_rounded
                                  : Icons.info_outline_rounded,
                          size: 16,
                          color: issue.severity == IntegritySeverity.error
                              ? AppTheme.error
                              : issue.severity == IntegritySeverity.warning
                                  ? AppTheme.warning
                                  : AppTheme.info,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(issue.tipe,
                                        style: TextStyle(fontSize: 9, color: AppTheme.textSecondaryOf(context))),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(issue.judul,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(issue.detail,
                                  style: TextStyle(fontSize: 10, color: AppTheme.textHintOf(context))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ],
      ),
      ),
    );
  }

  // ==================== ACTIVITY LOG SECTION ====================

  // Integrity check state
  IntegrityResult? _integrityResult;
  bool _isCheckingIntegrity = false;

  List<Map<String, dynamic>> _activityLogs = [];
  int _logCount = 0;
  String? _logFilter;

  Future<void> _loadActivityLogs() async {
    final logs = _logFilter != null
        ? await _localDB.getActivityLogsByType(_logFilter!, limit: 30)
        : await _localDB.getActivityLogs(limit: 30);
    final count = await _localDB.getActivityLogCount();
    if (mounted) {
      setState(() {
        _activityLogs = logs;
        _logCount = count;
      });
    }
  }

  Future<void> _confirmClearLogs() async {
    if (_activityLogs.isEmpty) {
      _showSnackbar('Tidak ada log untuk dihapus.', AppTheme.textHintOf(context));
      return;
    }
    final confirmed = await _showConfirmDialog(
      'Hapus Log Aktivitas',
      'Semua log aktivitas akan dihapus permanen. Lanjutkan?',
      isDanger: true,
    );
    if (confirmed != true) return;
    await _localDB.clearActivityLogs();
    await _loadActivityLogs();
    if (mounted) _showSnackbar('Log aktivitas berhasil dihapus.', AppTheme.success);
  }

  Widget _buildActivityLogSection(BuildContext context) {
    final logTypes = ['Semua', 'Penduduk', 'Keluarga', 'Catatan', 'Dasawisma', 'Anggota', 'Sistem'];
    // Colors for each log type
    final typeColors = {
      'Semua': AppTheme.primary,
      'Penduduk': AppTheme.primary,
      'Keluarga': AppTheme.info,
      'Catatan': AppTheme.female,
      'Dasawisma': AppTheme.success,
      'Anggota': AppTheme.warning,
      'Sistem': AppTheme.textSecondaryOf(context),
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Log count + clear button
            Row(
              children: [
                Icon(Icons.history_rounded, size: 16, color: AppTheme.textHintOf(context)),
                const SizedBox(width: 6),
                Text('$_logCount entri', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context))),
              const Spacer(),
              if (_activityLogs.isNotEmpty)
                GestureDetector(
                  onTap: _confirmClearLogs,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 12, color: AppTheme.error),
                        const SizedBox(width: 4),
                        Text('Hapus', style: TextStyle(fontSize: 10, color: AppTheme.error, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Filter chips
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: logTypes.map((type) {
                final isActive = (_logFilter == null && type == 'Semua') || _logFilter == type;
                final color = typeColors[type] ?? AppTheme.textHintOf(context);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _logFilter = type == 'Semua' ? null : type);
                      _loadActivityLogs();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive ? color.withValues(alpha: 0.3) : AppTheme.borderOf(context),
                        ),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive ? color : AppTheme.textSecondaryOf(context),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Log list or empty state
          if (_activityLogs.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded, size: 20, color: AppTheme.textHintOf(context)),
                    const SizedBox(width: 8),
                    Text('Belum ada aktivitas tercatat', style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _activityLogs.asMap().entries.map((entry) {
                final log = entry.value;
                final tipe = log['tipe'] as String? ?? '';
                final aksi = log['aksi'] as String? ?? '';
                final deskripsi = log['deskripsi'] as String? ?? '';
                final detail = log['detail'] as String? ?? '';
                final createdAt = log['created_at'] as String? ?? '';
                final color = typeColors[tipe] ?? AppTheme.textHintOf(context);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline dot
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Tipe badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(tipe, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 4),
                                // Aksi badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(aksi, style: TextStyle(fontSize: 9, color: AppTheme.textSecondaryOf(context))),
                                ),
                                const Spacer(),
                                Text(
                                  _formatTimestamp(createdAt),
                                  style: TextStyle(fontSize: 9, color: AppTheme.textHintOf(context)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              deskripsi,
                              style: TextStyle(fontSize: 12, color: AppTheme.textPrimaryOf(context)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (detail.isNotEmpty)
                              Text(
                                detail,
                                style: TextStyle(fontSize: 10, color: AppTheme.textHintOf(context), fontStyle: FontStyle.italic),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
      ),
    );
  }

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m yang lalu';
      if (diff.inHours < 24) return '${diff.inHours}j yang lalu';
      if (diff.inDays < 7) return '${diff.inDays}h yang lalu';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildMaintenanceSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Clear pending
          _actionTile(
            icon: Icons.cloud_off_outlined,
            title: 'Hapus Data Pending',
            subtitle: '${_pendingStats.values.fold(0, (a,b) => a+b)} data belum dikirim',
            color: AppTheme.warning,
            onTap: _confirmClearPending,
          ),
          const Divider(height: 8),

          // Full reset
          _actionTile(
            icon: Icons.restart_alt_rounded,
            title: 'Reset Semua Data Offline',
            subtitle: '${_totalCache + _totalPending} entri akan dihapus',
            color: AppTheme.error,
            onTap: _confirmResetAll,
          ),
        ],
      ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textHintOf(context)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 0,
      visualDensity: VisualDensity.compact,
    );
  }
}
