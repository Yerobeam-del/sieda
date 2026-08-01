import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../database/local_database.dart';
import '../../models/catatan_model.dart';
import '../../providers/catatan_provider.dart';
import '../../services/activity_service.dart';
import '../../services/connectivity_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_display.dart';
import '../../widgets/animations/page_transitions.dart';
import '../../widgets/pending_sync_badge.dart';
import 'catatan_form_screen.dart';

class CatatanDetailScreen extends StatefulWidget {
  final int catatanId;

  const CatatanDetailScreen({super.key, required this.catatanId});

  @override
  State<CatatanDetailScreen> createState() => _CatatanDetailScreenState();
}

class _CatatanDetailScreenState extends State<CatatanDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatatanProvider>().loadDetail(widget.catatanId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CatatanProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Catatan'),
        actions: [
          if (prov.selectedCatatan?.isPendingSync == true)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Center(child: PendingSyncBadge()),
            ),
          if (prov.selectedCatatan != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  SlideTransitionRoute(
                    page: CatatanFormScreen(catatan: prov.selectedCatatan),
                  ),
                );
                if (result == true) prov.loadDetail(widget.catatanId);
              },
            ),
        ],
      ),
      body: prov.isLoading
          ? const LoadingWidget()
          : prov.error != null
              ? ErrorDisplay(error: prov.error, onRetry: () => prov.loadDetail(widget.catatanId))
              : prov.selectedCatatan == null
                  ? const EmptyState(icon: Icons.baby_changing_station_rounded, title: 'Catatan tidak ditemukan')
                  : _buildContent(context, prov.selectedCatatan!),
    );
  }

  Widget _buildContent(BuildContext context, CatatanKelahiranKematianModel c) {
    final isDeath = c.isDeath;
    final statusColor = isDeath
        ? AppTheme.error
        : c.statusIbu?.toLowerCase() == 'hamil'
            ? AppTheme.female
            : c.statusIbu?.toLowerCase() == 'melahirkan'
                ? AppTheme.success
                : AppTheme.info;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ============ HEADER ============
          _buildHeader(context, c, statusColor),
          const SizedBox(height: 16),

          // ============ DATA IBU ============
          if (c.namaIbu != null) ...[
            _sectionTitle(context, Icons.person_rounded, 'Data Ibu', AppTheme.female),
            const SizedBox(height: 8),
            _infoCard(context, [
              _infoRow(context, 'NIK Ibu', c.nikIbu ?? c.idWargaIbu ?? '-'),
              _infoRow(context, 'Nama Ibu', c.namaIbu!),
              _infoRow(context, 'No. KK', c.noKk ?? '-'),
              _infoRow(context, 'Kelompok', c.kelompokDisplay),
            ]),
            const SizedBox(height: 16),
          ],

          // ============ DATA SUAMI ============
          if (c.namaSuami != null) ...[
            _sectionTitle(context, Icons.person_rounded, 'Data Suami', AppTheme.male),
            const SizedBox(height: 8),
            _infoCard(context, [
              _infoRow(context, 'NIK Suami', c.nikSuami ?? c.idWargaSuami ?? '-'),
              _infoRow(context, 'Nama Suami', c.namaSuami!),
            ]),
            const SizedBox(height: 16),
          ],

          // ============ STATUS KEHAMILAN ============
          _sectionTitle(context, Icons.health_and_safety_rounded, 'Status Kehamilan', AppTheme.female),
          const SizedBox(height: 8),
          _infoCard(context, [
            _infoRow(context, 'Status Ibu', c.statusIbuLabel),
            // Hamil: tampilkan tanggal hamil (legacy: bulan hamil)
            if (c.bulanHamil != null) _infoRow(context, 'Bulan Hamil', DateFormat('MMMM', 'id').format(DateTime(2000, c.bulanHamil!))),
            if (c.bulanHamil == null && c.tanggalHamil != null) _infoRow(context, 'Tanggal Hamil', c.tanggalHamil!),
            if (c.tanggalPerkiraanLahir != null) _infoRow(context, 'Perkiraan Lahir', c.tanggalPerkiraanLahir!),
            if (c.tanggalMelahirkan != null) _infoRow(context, 'Tanggal Melahirkan', c.tanggalMelahirkan!),
            if (c.tanggalNifasSelesai != null) _infoRow(context, 'Nifas Selesai', c.tanggalNifasSelesai!),
          ]),
          const SizedBox(height: 16),

          // ============ DATA BAYI ============
          if (c.hasBaby) ...[
            _sectionTitle(context, Icons.child_care_rounded, 'Data Bayi', AppTheme.success),
            const SizedBox(height: 8),
            _infoCard(context, [
              _infoRow(context, 'Nama Bayi', c.namaBayi!),
              _infoRow(context, 'Jenis Kelamin', c.jenisKelaminBayiLabel),
              if (c.tanggalLahirBayi != null) _infoRow(context, 'Tanggal Lahir', c.tanggalLahirBayi!),
              if (c.akteKelahiran != null) _infoRow(context, 'Akte Kelahiran', c.akteKelahiran!),
              if (c.noAkteKelahiran != null && c.noAkteKelahiran!.isNotEmpty)
                _infoRow(context, 'No. Akte', c.noAkteKelahiran!),
            ]),
            const SizedBox(height: 16),
          ],

          // ============ DATA KEMATIAN ============
          if (isDeath) ...[
            _sectionTitle(context, Icons.warning_amber_rounded, 'Data Kematian', AppTheme.error),
            const SizedBox(height: 8),
            _infoCard(context, [
              _infoRow(context, 'Status', c.statusKematianLabel),
              if (c.namaMeninggal != null) _infoRow(context, 'Nama Meninggal', c.namaMeninggal!),
              if (c.jenisKelaminMeninggal != null)
                _infoRow(context, 'Jenis Kelamin', Helpers.formatGender(c.jenisKelaminMeninggal)),
              if (c.tanggalMeninggal != null) _infoRow(context, 'Tanggal Meninggal', c.tanggalMeninggal!),
              if (c.sebabMeninggal != null && c.sebabMeninggal!.isNotEmpty)
                _infoRow(context, 'Sebab', c.sebabMeninggal!),
            ]),
            const SizedBox(height: 16),
          ],

          // ============ KETERANGAN ============
          if (c.keterangan != null && c.keterangan!.isNotEmpty) ...[
            _sectionTitle(context, Icons.notes_rounded, 'Keterangan', AppTheme.textHintOf(context)),
            const SizedBox(height: 8),
Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  c.keterangan!,
                  style: TextStyle(fontSize: 13, color: AppTheme.textPrimaryOf(context), height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ============ DELETE BUTTON ============
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDelete(context, c.id),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Hapus Catatan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CatatanKelahiranKematianModel c, Color statusColor) {
    final isDeath = c.isDeath;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isDeath ? AppTheme.error : statusColor,
            (isDeath ? AppTheme.error : statusColor).withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isDeath ? Icons.warning_amber_rounded : Icons.baby_changing_station_rounded,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            isDeath ? 'Kematian ${c.statusKematianLabel}' : c.statusIbuLabel,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tahun ${c.configYear}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
          ),
          if (c.namaIbu != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                c.namaIbu!,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _infoCard(BuildContext context, List<Widget> rows) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: rows[i],
            ),
            if (i < rows.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 12)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppTheme.textPrimaryOf(context), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Catatan'),
        content: const Text('Apakah Anda yakin ingin menghapus catatan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final isOnline = context.read<ConnectivityService>().isOnline;
              if (isOnline) {
                await context.read<CatatanProvider>().deleteCatatan(id);
              } else {
                // Offline: antrikan DELETE agar terkirim saat koneksi kembali.
                await LocalDatabase().queuePendingDeleteCatatan(id);
                await ActivityService().logDelete(
                  tipe: 'Catatan',
                  nama: 'Catatan #$id',
                  identifier: 'id: $id | Offline',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Catatan akan dihapus saat online.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
              if (context.mounted) Navigator.of(context).pop(true);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
