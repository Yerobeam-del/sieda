import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../services/connectivity_service.dart';

class ConnectivityBanner extends StatelessWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityService>().isOnline;

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: !isOnline
              ? Container(
                  width: double.infinity,
                  // Banner memanjang ke belakang status bar (edge-to-edge),
                  // tapi teksnya tetap di bawah inset status bar device.
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.paddingOf(context).top + 8,
                    20,
                    8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.warning.withValues(alpha: 0.12),
                        AppTheme.warning.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.isDark(context)
                            ? const Color(0xFFFEF3C7).withValues(alpha: 0.3)
                            : const Color(0xFFFEF3C7),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.warning,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.warning.withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Offline — data disimpan & dikirim saat online',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // Saat banner tampil, inset status bar sudah "dipakai" banner,
        // jadi padding atas dihapus dari MediaQuery layar di bawahnya
        // agar header tab (topInset) tidak jadi dobel spasi.
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: !isOnline,
            child: child,
          ),
        ),
      ],
    );
  }
}

class OnlineStatusIndicator extends StatelessWidget {
  const OnlineStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityService>().isOnline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isOnline ? AppTheme.success : AppTheme.warning).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isOnline ? AppTheme.success : AppTheme.warning,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isOnline ? AppTheme.success : AppTheme.warning).withValues(alpha: 0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
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
    );
  }
}
