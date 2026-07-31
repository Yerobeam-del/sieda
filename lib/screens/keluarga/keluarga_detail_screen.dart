import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../providers/keluarga_provider.dart';
import '../../models/penduduk_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_display.dart';
import '../../widgets/animations/page_transitions.dart';
import '../../widgets/pending_sync_badge.dart';
import '../penduduk/penduduk_detail_screen.dart';
import 'anggota_keluarga_screen.dart';

class KeluargaDetailScreen extends StatefulWidget {
  final String noKk;

  const KeluargaDetailScreen({super.key, required this.noKk});

  @override
  State<KeluargaDetailScreen> createState() => _KeluargaDetailScreenState();
}

class _KeluargaDetailScreenState extends State<KeluargaDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KeluargaProvider>().loadDetail(widget.noKk);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<KeluargaProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Keluarga'),
        actions: [
          if (prov.selectedKeluarga?.isPendingSync == true)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Center(child: PendingSyncBadge()),
            ),
          if (prov.selectedKeluarga != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => prov.loadDetail(widget.noKk),
            ),
        ],
      ),
      body: prov.isLoading
          ? const LoadingWidget()
          : prov.error != null
              ? ErrorDisplay(error: prov.error, onRetry: () => prov.loadDetail(widget.noKk))
              : prov.selectedKeluarga == null
                  ? const EmptyState(icon: Icons.family_restroom_outlined, title: 'Keluarga tidak ditemukan')
                  : _buildContent(context, prov.selectedKeluarga!),
    );
  }

  Widget _buildContent(BuildContext context, dynamic k) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryLight],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.family_restroom_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            k.kepalaKeluarga?.nama ?? 'Keluarga',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              k.noKk,
                              style: const TextStyle(fontFamily: 'monospace', color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (k.kelompokDasawisma != null)
                  _headerInfo('Kelompok', k.kelompokDasawisma.nama),
                if (k.kelompokDasawisma?.dusun != null)
                  _headerInfo('Dusun', k.kelompokDasawisma.dusun),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Data Kesehatan
          if (k.dasawismaKeluarga != null) ...[
            _sectionTitle('Data Kesehatan Keluarga'),
            const SizedBox(height: 8),
Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _healthItem(context, 'Balita', '${k.dasawismaKeluarga.jumlahBalita ?? 0}', Colors.orange),
                    _healthItem(context, 'Bumil', '${k.dasawismaKeluarga.jumlahIbuHamil ?? 0}', AppTheme.female),
                    _healthItem(context, 'Stunting', '${k.dasawismaKeluarga.jumlahStunting ?? 0}', AppTheme.error),
                    _healthItem(context, 'Lansia', '${k.dasawismaKeluarga.jumlahLansia ?? 0}', AppTheme.info),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Anggota Keluarga
          _sectionTitle('Anggota Keluarga (${k.anggota.length})'),
          const SizedBox(height: 8),
          ...k.anggota.map((PendudukModel a) => _anggotaCard(context, a)),
          const SizedBox(height: 8),
          // Kelola anggota: tambah/hapus dengan dukungan offline.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Tangkap provider sebelum async gap agar tidak ada
                // BuildContext dipakai di callback .then() (lint-safe).
                final prov = context.read<KeluargaProvider>();
                // Selalu muat ulang setelah kembali — screen anggota tidak
                // pernah pop dengan nilai, jadi abaikan hasilnya.
                Navigator.of(context).push(
                  SlideTransitionRoute(page: AnggotaKeluargaScreen(noKk: widget.noKk)),
                ).then((_) {
                  prov.loadDetail(widget.noKk);
                });
              },
              icon: const Icon(Icons.group_add_outlined, size: 18),
              label: const Text('Kelola Anggota Keluarga'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Hapus keluarga: online -> DELETE langsung; offline -> antrean.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDelete(context, k),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Hapus Keluarga'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Konfirmasi hapus keluarga. Online -> DELETE langsung; offline -> data
  /// diantrekan dan akan dihapus saat koneksi tersedia kembali.
  void _confirmDelete(BuildContext context, dynamic k) {
    final noKk = k.noKk as String;
    final namaKepala = k.kepalaKeluarga?.nama as String? ?? 'Keluarga';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Keluarga'),
        content: Text('Apakah Anda yakin ingin menghapus keluarga $namaKepala (No. KK $noKk)? Semua anggota dan catatan terkait juga akan terpengaruh.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await context.read<KeluargaProvider>().deleteKeluarga(k);
              if (!context.mounted) return;

              if (!result.handled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menghapus keluarga.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.queuedOffline
                      ? 'Keluarga akan dihapus saat online.'
                      : 'Keluarga berhasil dihapus.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              if (context.mounted) Navigator.of(context).pop(true);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _headerInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Row(
      children: [
        Container(width: 3, height: 18, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _healthItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context))),
      ],
    );
  }

  Widget _anggotaCard(BuildContext context, PendudukModel a) {
    final isMale = a.jenisKelamin?.toUpperCase().trim() == 'L' || a.jenisKelamin?.toUpperCase().trim() == 'LAKI-LAKI';
    final genderColor = isMale ? AppTheme.male : AppTheme.female;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PendudukDetailScreen(nik: a.nik)),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: genderColor.withValues(alpha: 0.15),
                child: Text(Helpers.getInitials(a.nama), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: genderColor)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.nama, style: Theme.of(context).textTheme.titleMedium),
                    Row(
                      children: [
                        Text(a.genderLabel, style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context))),
                        if (a.usiaLabel != '-') ...[
                          Text(' | ', style: TextStyle(fontSize: 11, color: AppTheme.textHintOf(context))),
                          Text(a.usiaLabel, style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context))),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textHintOf(context)),
            ],
          ),
        ),
      ),
    );
  }
}
