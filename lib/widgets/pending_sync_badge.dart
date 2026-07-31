import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Badge kecil "Menunggu sinkron" untuk item yang disimpan offline dan
/// belum terkirim ke server — dipakai di kartu list & detail.
class PendingSyncBadge extends StatelessWidget {
  const PendingSyncBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_upload_outlined, size: 11, color: AppTheme.warning),
          SizedBox(width: 4),
          Text(
            'Menunggu sinkron',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.warning,
            ),
          ),
        ],
      ),
    );
  }
}
