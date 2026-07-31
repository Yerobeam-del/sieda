import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/catatan_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/penduduk_provider.dart';
import 'providers/keluarga_provider.dart';
import 'providers/dasawisma_provider.dart';
import 'providers/rekapitulasi_provider.dart';
import 'providers/reference_provider.dart';
import 'providers/theme_provider.dart';
import 'database/local_database.dart';
import 'services/activity_service.dart';
import 'services/connectivity_service.dart';
import 'services/sync_service.dart';
import 'screens/auth/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-warm SharedPreferences so ThemeProvider loads instantly.
  await SharedPreferences.getInstance();

  // Initialize Indonesian locale for DateFormat('MMMM', 'id').
  await initializeDateFormatting('id', null);

  runApp(const SiEdaApp());

  // Pembersihan otomatis item pending yang sudah terkirim (synced=1) dan
  // berusia > 30 hari — berjalan di background, tidak memblokir startup.
  unawaited(_maybeCleanupOldSynced());
}

/// Bersihkan item synced lama, maksimal SEKALI SEHARI.
/// Dipanggil saat app dibuka dan dari timer retry berkala (3 menit) —
/// penanda `last_cleanup_at` mencegah pembersihan berulang dalam 24 jam
/// sehingga app yang dibiarkan terbuka berhari-hari tetap terjaga bersih.
Future<void> _maybeCleanupOldSynced() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final lastRaw = prefs.getString(LocalDatabase.lastCleanupAtKey);
    if (lastRaw != null) {
      final lastTime = DateTime.tryParse(lastRaw);
      if (lastTime != null &&
          DateTime.now().difference(lastTime) < const Duration(days: 1)) {
        return; // Sudah dibersihkan kurang dari 1 hari lalu.
      }
    }
    await _cleanupOldSynced();
  } catch (e) {
    debugPrint('[Cleanup] Gagal cek jadwal: $e');
  }
}

/// Hapus item synced lama dan catat ke activity log, lalu simpan penanda
/// `last_cleanup_at` + jumlah terhapus supaya tidak diulang dalam 24 jam dan
/// bisa ditampilkan sebagai statistik di halaman admin.
Future<void> _cleanupOldSynced() async {
  int deleted = 0;
  try {
    deleted = await LocalDatabase().cleanupOldSynced();
    if (deleted > 0) {
      await ActivityService().logMaintenance(
        aksi: 'Cleanup',
        deskripsi: '$deleted data synced lama dibersihkan otomatis',
        detail: 'Item pending yang sudah terkirim berusia > 30 hari dihapus.',
      );
      debugPrint('[Cleanup] $deleted item synced lama dihapus.');
    }
  } catch (e) {
    debugPrint('[Cleanup] Gagal: $e');
  }

  // Tandai waktu pembersihan + jumlah terhapus (selesai atau gagal tetap
  // dicatat agar tidak memukul DB tiap 3 menit saat ada error persisten).
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LocalDatabase.lastCleanupAtKey, DateTime.now().toIso8601String());
    await prefs.setInt(LocalDatabase.lastCleanupDeletedKey, deleted);
  } catch (e) {
    debugPrint('[Cleanup] Gagal simpan penanda: $e');
  }
}

class SiEdaApp extends StatelessWidget {
  const SiEdaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        ChangeNotifierProvider(create: (_) => ConnectivityService()),

        // State providers
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => PendudukProvider()),
        ChangeNotifierProvider(create: (_) => KeluargaProvider()),
        ChangeNotifierProvider(create: (_) => DasawismaProvider()),
        ChangeNotifierProvider(create: (_) => RekapitulasiProvider()),
        ChangeNotifierProvider(create: (_) => ReferenceProvider()),
        ChangeNotifierProvider(create: (_) => CatatanProvider()),

        // Theme – a singleton that loads its persisted value on first access
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'SIEDA',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            // builder dipakai agar _AutoSyncListener tetap hidup di SEMUA rute
            // (bukan hanya splash screen yang segera diganti oleh Home).
            builder: (context, child) => _AutoSyncListener(child: child ?? const SizedBox.shrink()),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

/// Otomatis mengirim data pending begitu perangkat kembali online,
/// sehingga data yang dimasukkan offline langsung tersinkronisasi ke server
/// tanpa perlu user menekan tombol sinkronisasi.
class _AutoSyncListener extends StatefulWidget {
  final Widget child;

  const _AutoSyncListener({required this.child});

  @override
  State<_AutoSyncListener> createState() => _AutoSyncListenerState();
}

class _AutoSyncListenerState extends State<_AutoSyncListener> {
  bool _lastOnline = true;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    // Retry berkala: setiap 3 menit coba ulang item pending yang sudah lewat
    // masa backoff-nya (mis. gagal karena server error 500 / jaringan putus).
    _retryTimer = Timer.periodic(const Duration(minutes: 3), (_) => _periodicRetry());
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityService>();

    // Transisi offline -> online: jalankan sinkronisasi otomatis (sekali saja).
    if (!_lastOnline && connectivity.isOnline) {
      _lastOnline = true;
      _autoSync(connectivity);
    } else if (connectivity.isOnline != _lastOnline) {
      _lastOnline = connectivity.isOnline;
    }

    return widget.child;
  }

  Future<void> _periodicRetry() async {
    // Ambil reference sebelum await agar tidak ada use_build_context_synchronously.
    final connectivity = context.read<ConnectivityService>();
    try {
      // Pembersihan berkala: item synced lama dibersihkan maksimal sekali
      // sehari (penanda last_cleanup_at). Berjalan di sini agar app yang
      // dibiarkan terbuka berhari-hari juga tetap bersih — tidak butuh
      // internet, jadi dipanggil sebelum guard koneksi.
      await _maybeCleanupOldSynced();

      if (!mounted) return;
      if (!connectivity.isOnline) return;
      // Hanya jika ada item yang siap dicoba ulang (masa backoff sudah lewat).
      final ready = await LocalDatabase().getPendingReadyCount();
      if (ready == 0) return;
      final result = await SyncService(connectivity).syncAll();
      debugPrint('[AutoSync] Retry berkala: ${result.message} (${result.success} ok, ${result.failed} gagal, ${result.deferred} ditunda)');
      await _refreshDataAfterSync(result.success);
    } catch (e) {
      debugPrint('[AutoSync] Retry berkala gagal: $e');
    }
  }

  Future<void> _autoSync(ConnectivityService connectivity) async {
    try {
      final result = await SyncService(connectivity).syncAll();
      debugPrint('[AutoSync] ${result.message} (${result.success} ok, ${result.failed} gagal)');
      await _refreshDataAfterSync(result.success);
    } catch (e) {
      debugPrint('[AutoSync] Gagal: $e');
    }
  }

  /// Setelah sinkron berhasil, muat ulang data dari server agar daftar
  /// langsung menampilkan hasil sinkron — badge "Menunggu sinkron" hilang
  /// tanpa perlu restart atau menekan tombol refresh manual.
  Future<void> _refreshDataAfterSync(int successCount) async {
    if (successCount <= 0 || !mounted) return;
    try {
      final ctx = context;
      await Future.wait([
        ctx.read<PendudukProvider>().loadPenduduk(refresh: true),
        ctx.read<KeluargaProvider>().loadKeluarga(refresh: true),
        ctx.read<CatatanProvider>().loadCatatan(),
        ctx.read<DasawismaProvider>().loadKelompok(),
      ]);
    } catch (e) {
      debugPrint('[AutoSync] Gagal memuat ulang data: $e');
    }
  }
}
