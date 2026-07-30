import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../providers/auth_provider.dart';
import '../../services/connectivity_service.dart';
import '../../services/sync_service.dart';
import '../../database/local_database.dart';
import '../admin/admin_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _pendingSyncCount = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
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

  Future<void> _syncNow() async {
    final connectivity = context.read<ConnectivityService>();
    if (!connectivity.isOnline) {
      _showSnackbar('Tidak ada koneksi internet.');
      return;
    }

    setState(() => _isSyncing = true);
    final syncService = SyncService(connectivity);
    final result = await syncService.syncAll();
    await _loadPendingCount();
    if (mounted) {
      setState(() => _isSyncing = false);
      _showSnackbar(result.message);
    }
  }

  void _showSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isOnline = context.watch<ConnectivityService>().isOnline;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: false,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: AppTheme.gradientHeader,
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        // Avatar with photo support
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 34,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                                  ? CachedNetworkImageProvider(user.avatarUrl!)
                                  : null,
                              child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                                  ? Text(
                                      Helpers.getInitials(user?.name),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            // Online/offline indicator
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: isOnline ? AppTheme.success : AppTheme.warning,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'User',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.email ?? '',
                                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  if (user != null && user.roles.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        user.roleLabel,
                                        style: const TextStyle(color: Colors.white, fontSize: 11),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  // Online status badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (isOnline ? AppTheme.success : AppTheme.warning).withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: isOnline ? AppTheme.success : AppTheme.warning,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isOnline ? 'Online' : 'Offline',
                                          style: const TextStyle(color: Colors.white, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Info section
                // Sync Status Card
              _buildSyncStatusCard(context),
              const SizedBox(height: 16),

              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Informasi Akun', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      _profileRow('Username', user?.username ?? '-'),
                      const Divider(height: 16),
                      _profileRow('Email', user?.email ?? '-'),
                      const Divider(height: 16),
                      _profileRow('Role', user?.roleLabel ?? '-'),
                      if (user?.desaName != null) ...[
                        const Divider(height: 16),
                        _profileRow('Desa', user!.desaName!),
                      ],
                      if (user?.kecamatanName != null) ...[
                        const Divider(height: 16),
                        _profileRow('Kecamatan', user!.kecamatanName!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Menu items
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    children: [
                      _menuItem(
                        context,
                        icon: Icons.settings_outlined,
                        title: 'Pengaturan Offline',
                        color: AppTheme.textSecondary,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminScreen()),
                        ),
                      ),
                      const Divider(height: 4),
                      _menuItem(
                        context,
                        icon: Icons.logout_rounded,
                        title: 'Logout',
                        color: AppTheme.error,
                        onTap: () => _showLogoutDialog(context),
                      ),
                      const Divider(height: 4),
                      _menuItem(
                        context,
                        icon: Icons.logout_rounded,
                        title: 'Logout dari Semua Perangkat',
                        color: AppTheme.error,
                        onTap: () => _showLogoutAllDialog(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'SIEDA v1.0\nSistem Informasi e-Dasawisma',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _menuItem(BuildContext context, {required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint, size: 20),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      minLeadingWidth: 0,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSyncStatusCard(BuildContext context) {
    final isOnline = context.watch<ConnectivityService>().isOnline;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _pendingSyncCount > 0 ? AppTheme.warning.withOpacity(0.5) : AppTheme.success.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _pendingSyncCount > 0 ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
                color: _pendingSyncCount > 0 ? AppTheme.warning : AppTheme.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Sinkronisasi Data', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isOnline ? AppTheme.success : AppTheme.warning).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? AppTheme.success : AppTheme.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOnline ? AppTheme.success : AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Pending count badge
              if (_pendingSyncCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$_pendingSyncCount menunggu',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warning,
                    ),
                  ),
                )
              else
                const Text(
                  'Semua tersinkronisasi',
                  style: TextStyle(fontSize: 11, color: AppTheme.success, fontWeight: FontWeight.w500),
                ),
            ],
          ),
          if (_pendingSyncCount > 0) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _isSyncing ? null : _syncNow,
                icon: _isSyncing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sync_rounded, size: 18),
                label: Text(_isSyncing ? 'Menyinkronkan...' : 'Sinkronkan Sekarang'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  backgroundColor: AppTheme.primary.withOpacity(0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLogoutAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout Semua'),
        content: const Text('Anda akan logout dari semua perangkat. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().logoutAll();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text('Logout Semua', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
