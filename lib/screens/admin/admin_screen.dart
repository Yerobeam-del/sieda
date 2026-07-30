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
  int _totalCache = 0;
  int _totalPending = 0;
  bool _isLoading = true;
  bool _isSyncing = false;
  String? _lastSyncMessage;

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
      final totalCache = await _localDB.getTotalCacheCount();
      final totalPending = await _localDB.getTotalPendingCount();
      await _loadActivityLogs();
      if (mounted) {
        setState(() {
          _cacheStats = cacheStats;
          _pendingStats = pendingStats;
          _totalCache = totalCache;
          _totalPending = totalPending;
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
      });
      _showSnackbar(result.message, result.failed > 0 ? AppTheme.warning : AppTheme.success);
    }
  }

  Future<void> _confirmClearCache() async {
    if (_totalCache == 0) {
      _showSnackbar('Tidak ada cache untuk dihapus.', AppTheme.textHint);
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
      _showSnackbar('Tidak ada data pending.', AppTheme.textHint);
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
        content: Text(content, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
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

                // ============ SECTION 2: RINCIAN PENDING ============
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
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
                  color: (isOnline ? AppTheme.success : AppTheme.warning).withOpacity(0.1),
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
              backgroundColor: AppTheme.border,
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
          const SizedBox(height: 12),

          if (_lastSyncMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _lastSyncMessage!,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
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
    );
  }

  // ==================== PENDING DETAILS ====================

  Widget _buildPendingDetails() {
    final labels = {
      'Penduduk': Icons.people_outline_rounded,
      'Keluarga': Icons.family_restroom_outlined,
      'Catatan': Icons.baby_changing_station_rounded,
      'Dasawisma': Icons.groups_outlined,
    };

    final colors = {
      'Penduduk': AppTheme.primary,
      'Keluarga': AppTheme.info,
      'Catatan': AppTheme.female,
      'Dasawisma': AppTheme.success,
    };

    final hasData = _pendingStats.values.any((c) => c > 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: hasData
          ? Column(
              children: _pendingStats.entries.map((entry) {
                final label = entry.key;
                final count = entry.value;
                final icon = labels[label] ?? Icons.pending_rounded;
                final color = colors[label] ?? AppTheme.textHint;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, size: 18, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: count > 0 ? AppTheme.warning.withOpacity(0.15) : AppTheme.success.withOpacity(0.1),
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
                );
              }).toList(),
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_done_rounded, size: 20, color: AppTheme.success),
                    SizedBox(width: 8),
                    Text('Tidak ada data pending', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
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
                  Icon(icon, size: 16, color: AppTheme.textHint),
                  const SizedBox(width: 8),
                  Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
                  Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
          const Divider(height: 16),
          Row(
            children: [
              const Icon(Icons.storage_rounded, size: 16, color: AppTheme.textPrimary),
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
                  side: BorderSide(color: AppTheme.error.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
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
                  side: BorderSide(color: AppTheme.primary.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            )
          else if (_isCheckingIntegrity)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    CircularProgressIndicator(strokeWidth: 2.5),
                    SizedBox(height: 12),
                    Text('Memeriksa data offline...',
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
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
                      color: AppTheme.primary.withOpacity(0.1),
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
                                      color: AppTheme.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(issue.tipe,
                                        style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
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
                                  style: const TextStyle(fontSize: 10, color: AppTheme.textHint)),
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
      _showSnackbar('Tidak ada log untuk dihapus.', AppTheme.textHint);
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
    final logTypes = ['Semua', 'Penduduk', 'Keluarga', 'Catatan', 'Dasawisma', 'Sistem'];
    // Colors for each log type
    final typeColors = {
      'Semua': AppTheme.primary,
      'Penduduk': AppTheme.primary,
      'Keluarga': AppTheme.info,
      'Catatan': AppTheme.female,
      'Dasawisma': AppTheme.success,
      'Sistem': AppTheme.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Log count + clear button
          Row(
            children: [
              Icon(Icons.history_rounded, size: 16, color: AppTheme.textHint),
              const SizedBox(width: 6),
              Text('$_logCount entri', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const Spacer(),
              if (_activityLogs.isNotEmpty)
                GestureDetector(
                  onTap: _confirmClearLogs,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
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
                final color = typeColors[type] ?? AppTheme.textHint;
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
                        color: isActive ? color.withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive ? color.withOpacity(0.3) : AppTheme.border,
                        ),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive ? color : AppTheme.textSecondary,
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
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_rounded, size: 20, color: AppTheme.textHint),
                    SizedBox(width: 8),
                    Text('Belum ada aktivitas tercatat', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
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
                final color = typeColors[tipe] ?? AppTheme.textHint;

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
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(tipe, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
                                ),
                                const SizedBox(width: 4),
                                // Aksi badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(aksi, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
                                ),
                                const Spacer(),
                                Text(
                                  _formatTimestamp(createdAt),
                                  style: const TextStyle(fontSize: 9, color: AppTheme.textHint),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              deskripsi,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (detail.isNotEmpty)
                              Text(
                                detail,
                                style: const TextStyle(fontSize: 10, color: AppTheme.textHint, fontStyle: FontStyle.italic),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration,
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppTheme.textHint),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 0,
      visualDensity: VisualDensity.compact,
    );
  }
}
