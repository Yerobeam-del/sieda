import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../services/connectivity_service.dart';
import '../../services/sync_service.dart';
import '../../database/local_database.dart';
import '../../widgets/connectivity_banner.dart';
import '../catatan/catatan_list_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../penduduk/penduduk_list_screen.dart';
import '../keluarga/keluarga_list_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _pendingSyncCount = 0;
  late AnimationController _fabAnimationController;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const PendudukListScreen(),
    const KeluargaListScreen(),
    const CatatanListScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadPendingCount();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingCount() async {
    try {
      final localDB = LocalDatabase();
      final penduduk = await localDB.getUnsyncedPenduduk();
      final keluarga = await localDB.getUnsyncedKeluarga();
      if (mounted) {
        setState(() => _pendingSyncCount = penduduk.length + keluarga.length);
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
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
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConnectivityBanner(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: _buildAnimatedNavBar(context),
      floatingActionButton: _currentIndex == 4
          ? FloatingActionButton(
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
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Icon(Icons.cloud_done_rounded),
            )
          : _currentIndex == 0
              ? FloatingActionButton.small(
                  onPressed: () {
                    final dashboard = context.read<DashboardProvider>();
                    dashboard.loadDashboard();
                  },
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primary,
                  tooltip: 'Refresh Dashboard',
                  child: const Icon(Icons.refresh_rounded),
                )
              : null,
    );
  }

  Widget _buildAnimatedNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isActive = _currentIndex == index;
              return _NavBarItem(
                icon: isActive ? item.activeIcon : item.icon,
                label: item.label,
                isActive: isActive,
                onTap: () {
                  setState(() => _currentIndex = index);
                },
              );
            }),
          ),
        ),
      ),
    );
  }

  static const _navItems = [
    _NavItemData(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    _NavItemData(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      label: 'Penduduk',
    ),
    _NavItemData(
      icon: Icons.family_restroom_outlined,
      activeIcon: Icons.family_restroom,
      label: 'Keluarga',
    ),
    _NavItemData(
      icon: Icons.baby_changing_station_rounded,
      activeIcon: Icons.baby_changing_station_rounded,
      label: 'Ibu & Anak',
    ),
    _NavItemData(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profil',
    ),
  ];
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItemData({required this.icon, required this.activeIcon, required this.label});
}

class _NavBarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_NavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _scaleController.forward().then((_) => _scaleController.reverse());
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Icon(
                  widget.icon,
                  key: ValueKey(widget.isActive),
                  size: 22,
                  color: widget.isActive ? AppTheme.primary : AppTheme.textHint,
                ),
              ),
              if (widget.isActive) ...[
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
