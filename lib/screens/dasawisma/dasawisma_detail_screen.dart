import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/dasawisma_provider.dart';
import '../../models/dasawisma_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_display.dart';
import '../../widgets/animations/page_transitions.dart';
import '../../widgets/pending_sync_badge.dart';
import 'dasawisma_form_screen.dart';

class KelompokDetailScreen extends StatefulWidget {
  final int kelompokId;

  const KelompokDetailScreen({super.key, required this.kelompokId});

  @override
  State<KelompokDetailScreen> createState() => _KelompokDetailScreenState();
}

class _KelompokDetailScreenState extends State<KelompokDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DasawismaProvider>().loadKelompokDetail(widget.kelompokId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DasawismaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kelompok'),
        actions: [
          if (prov.selectedKelompok?.isPendingSync == true)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: PendingSyncBadge()),
            ),
        ],
      ),
      body: prov.isLoading
          ? const LoadingWidget()
          : prov.error != null
              ? ErrorDisplay(error: prov.error, onRetry: () => prov.loadKelompokDetail(widget.kelompokId))
              : prov.selectedKelompok == null
                  ? const EmptyState(icon: Icons.groups_outlined, title: 'Kelompok tidak ditemukan')
                  : _buildContent(context, prov.selectedKelompok!),
    );
  }

  Widget _buildContent(BuildContext context, KelompokDasawismaModel k) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryLight],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.groups_rounded, size: 36, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(k.nama, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                if (k.dusun != null)
                  Text('Dusun ${k.dusun}', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
                if (k.namaKader != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text('Kader: ${k.namaKader}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _statBadge('KK', '${k.totalKeluarga ?? 0}', AppTheme.info),
                    const SizedBox(width: 12),
                    _statBadge('Anggota', '${k.totalAnggota ?? 0}', AppTheme.success),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Actions — form Data Kesehatan Keluarga diakses per keluarga
          // (halaman Detail Keluarga) atau lewat tab Keluarga di Dasawisma.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final provider = context.read<DasawismaProvider>();
                Navigator.of(context).push(SlideTransitionRoute(
                  page: DasawismaKelompokFormScreen(kelompok: k),
                )).then((_) {
                  if (mounted) {
                    provider.loadKelompokDetail(widget.kelompokId);
                  }
                });
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit Kelompok'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Info card
          Card(
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
                  Text('Informasi Kelompok', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _infoRow(context, 'Nama', k.nama),
                  _infoRow(context, 'Dusun', k.dusun ?? '-'),
                  _infoRow(context, 'Kader', k.namaKader ?? '-'),
                  _infoRow(context, 'Tahun', k.configYear.toString()),
                  _infoRow(context, 'Total KK', '${k.totalKeluarga ?? 0}'),
                  _infoRow(context, 'Total Anggota', '${k.totalAnggota ?? 0}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _statBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context)))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
