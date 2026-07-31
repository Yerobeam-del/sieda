import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/connectivity_service.dart';
import '../../services/sync_service.dart';
import '../../database/local_database.dart';
import '../../widgets/connectivity_banner.dart';
import '../../widgets/animations/page_transitions.dart';
import '../../providers/penduduk_provider.dart';
import '../../providers/keluarga_provider.dart';
import '../../providers/catatan_provider.dart';
import '../catatan/catatan_list_screen.dart';
import '../catatan/catatan_form_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../penduduk/penduduk_list_screen.dart';
import '../penduduk/forms/penduduk_form_screen.dart';
import '../keluarga/keluarga_list_screen.dart';
import '../keluarga/forms/keluarga_form_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _pendingSyncCount = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    PendudukListScreen(),
    KeluargaListScreen(),
    CatatanListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    try {
      final total = await LocalDatabase().getTotalPendingCount();
      if (mounted) {
        setState(() => _pendingSyncCount = total);
      }
    } catch (_) {}
  }

  Future<void> _syncData() async {
    final connectivity = context.read<ConnectivityService>();
    if (!connectivity.isOnline) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Tidak ada koneksi internet.'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final syncService = SyncService(connectivity);
    final result = await syncService.syncAll();
    await _loadPendingCount();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result.failed > 0 ? Icons.warning_rounded : Icons.cloud_done_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(result.message)),
          ],
        ),
        backgroundColor: result.failed > 0 ? AppTheme.warning : AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: ConnectivityBanner(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: _buildNavigationBar(context),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget? _buildFab(BuildContext context) {
    switch (_currentIndex) {
      case 1: // Penduduk
        return FloatingActionButton.extended(
          onPressed: () {
            final prov = context.read<PendudukProvider>();
            Navigator.of(context).push(
              SlideTransitionRoute(page: const PendudukFormScreen()),
            ).then((result) {
              if (result == true && mounted) {
                prov.loadPenduduk(refresh: true);
              }
            });
          },
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_rounded, size: 20),
          label: const Text('Tambah'),
        );
      case 2: // Keluarga
        return FloatingActionButton.extended(
          onPressed: () {
            final prov = context.read<KeluargaProvider>();
            Navigator.of(context).push(
              SlideTransitionRoute(page: const KeluargaFormScreen()),
            ).then((result) {
              if (result == true && mounted) {
                prov.loadKeluarga(refresh: true);
              }
            });
          },
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
          label: const Text('Tambah'),
        );
      case 3: // Ibu & Anak
        return FloatingActionButton.extended(
          onPressed: () {
            final prov = context.read<CatatanProvider>();
            Navigator.of(context).push(
              SlideTransitionRoute(page: const CatatanFormScreen()),
            ).then((result) {
              if (result == true && mounted) {
                prov.loadCatatan(refresh: true);
              }
            });
          },
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Tambah'),
        );
      case 4: // Profile — sync button
        return FloatingActionButton(
          onPressed: _syncData,
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          tooltip: 'Sinkronisasi Data',
          child: _pendingSyncCount > 0
              ? Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.sync_rounded),
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_pendingSyncCount',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : const Icon(Icons.cloud_done_rounded),
        );
      case 0: // Dashboard — refresh
        return FloatingActionButton.small(
          onPressed: () {
            context.read<DashboardProvider>().loadDashboard();
          },
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: AppTheme.primary,
          tooltip: 'Refresh Dashboard',
          child: const Icon(Icons.refresh_rounded),
        );
      default:
        return null;
    }
  }

  Widget _buildNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            animationDuration: const Duration(milliseconds: 400),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(Icons.people_rounded),
                label: 'Penduduk',
              ),
              NavigationDestination(
                icon: Icon(Icons.family_restroom_outlined),
                selectedIcon: Icon(Icons.family_restroom),
                label: 'Keluarga',
              ),
              NavigationDestination(
                icon: Icon(Icons.baby_changing_station_outlined),
                selectedIcon: Icon(Icons.baby_changing_station_rounded),
                label: 'Ibu & Anak',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
