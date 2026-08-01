import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/penduduk_model.dart';
import '../../providers/penduduk_provider.dart';
import '../../providers/keluarga_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_display.dart';
import '../../widgets/pending_sync_badge.dart';
import '../../widgets/animations/page_transitions.dart';
import '../dasawisma/dasawisma_keluarga_form_screen.dart';

class PendudukDetailScreen extends StatefulWidget {
  final String nik;

  const PendudukDetailScreen({super.key, required this.nik});

  @override
  State<PendudukDetailScreen> createState() => _PendudukDetailScreenState();
}

class _PendudukDetailScreenState extends State<PendudukDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PendudukProvider>().loadDetail(widget.nik);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PendudukProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Penduduk'),
        actions: [
          if (prov.selectedPenduduk?.isPendingSync == true)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: PendingSyncBadge()),
            ),
        ],
      ),
      body: prov.isLoading
          ? const LoadingWidget()
          : prov.error != null
              ? ErrorDisplay(error: prov.error, onRetry: () => prov.loadDetail(widget.nik))
              : prov.selectedPenduduk == null
                  ? const EmptyState(icon: Icons.person_off_rounded, title: 'Penduduk tidak ditemukan')
                  : _buildContent(context, prov.selectedPenduduk!),
    );
  }

  Widget _buildContent(BuildContext context, PendudukModel p) {
    final isMale = p.jenisKelamin?.toUpperCase().trim() == 'L' ||
        p.jenisKelamin?.toUpperCase().trim() == 'LAKI-LAKI';
    final genderColor = isMale ? AppTheme.male : AppTheme.female;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ============ HEADER ============
          _buildHeader(context, p, genderColor, isMale),

          const SizedBox(height: 16),

          // ============ DATA DIRI ============
          _sectionTitle(context, Icons.person_rounded, 'Data Diri'),
          const SizedBox(height: 8),
          _infoCard(context, [
            _infoRow(context, 'No. Registrasi', p.noRegistrasi ?? '-'),
            _infoRow(context, 'NIK', p.nik),
            _infoRow(context, 'Nama Lengkap', p.nama),
            _infoRow(context, 'Tempat, Tgl Lahir', p.formattedTtl),
            _infoRow(context, 'Usia', p.usiaLabel),
            _infoRow(context, 'Jenis Kelamin', p.genderLabel),
            _infoRow(context, 'Agama', p.agama ?? '-'),
            _infoRow(context, 'Pendidikan', p.pendidikan ?? '-'),
            _infoRow(context, 'Pekerjaan', p.pekerjaan ?? '-'),
            _infoRow(context, 'No. HP', Helpers.formatPhone(p.noHp)),
            _infoRow(context, 'Alamat', p.alamat ?? '-'),
          ]),
          const SizedBox(height: 16),

          // ============ STATUS KELUARGA ============
          _sectionTitle(context, Icons.family_restroom_rounded, 'Status Keluarga'),
          const SizedBox(height: 8),
          _infoCard(context, [
            _infoRow(context, 'Status Perkawinan', p.statusPerkawinan ?? '-'),
            _infoRow(context, 'Peran dalam Keluarga', p.peranKeluarga ?? '-'),
            _infoRow(context, 'Status dalam Keluarga', p.statusKeluarga ?? '-'),
          ]),
          const SizedBox(height: 16),

          // ============ PROGRAM PKK ============
          _sectionTitle(context, Icons.health_and_safety_rounded, 'Program PKK'),
          const SizedBox(height: 8),
          _infoCard(context, [
            _infoYesNo(context, 'Akseptor KB', p.statusAkseptor, p.jenisAkseptor),
            _infoYesNo(context, 'Posyandu', p.statusPosyandu, 
                p.frekuensiPosyandu != null ? '${p.frekuensiPosyandu}/${p.satuanFrekuensiVolume ?? "-"}' : null),
            _infoYesNo(context, 'BKB (Bina Keluarga Balita)', p.statusPbkb, null),
            _infoYesNo(context, 'Memiliki Tabungan', p.statusTabungan, null),
            _infoYesNo(context, 'Kelompok Belajar', p.statusKelompokBelajar, p.jenisKelompokBelajar),
            _infoYesNo(context, 'PAUD/Sejenis', p.statusPaud, null),
            _infoYesNo(context, 'Kegiatan Koperasi', p.statusKegiatanKoperasi, p.jenisKoperasi),
            _infoYesNo(context, 'Kebutuhan Khusus', p.statusKebutuhanKhusus, p.kebutuhanKhusus),
          ]),
          const SizedBox(height: 24),

          // ============ DATA KESEHATAN KELUARGA (DASAWISMA) ============
          if (p.noKk != null && p.noKk!.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _openDasawismaKeluargaForm(p.noKk!),
                icon: const Icon(Icons.health_and_safety_rounded, size: 18),
                label: Text('Data Kesehatan Keluarga (No. KK ${p.noKk})'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ============ HAPUS ============
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmDelete(context, p),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Hapus Penduduk'),
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

  /// Buka form Data Kesehatan Keluarga (Dasawisma) untuk No. KK keluarga
  /// terkait. Data yang sudah tersimpan di-pre-fetch dulu agar form terbuka
  /// dalam mode edit — mencegah data lama tertimpa saat menyimpan.
  Future<void> _openDasawismaKeluargaForm(String noKk) async {
    // Tangkap provider sebelum async gap (lint-safe).
    final keluargaProv = context.read<KeluargaProvider>();
    await keluargaProv.loadDetail(noKk);
    if (!mounted) return;
    final dk = keluargaProv.selectedKeluarga?.dasawismaKeluarga;
    Navigator.of(context).push(
      SlideTransitionRoute(
        page: DasawismaKeluargaFormScreen(initialNoKK: noKk, data: dk),
      ),
    );
  }

  /// Konfirmasi hapus penduduk. Online -> DELETE langsung; offline -> data
  /// diantrekan dan akan dihapus saat koneksi tersedia kembali.
  void _confirmDelete(BuildContext context, PendudukModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Penduduk'),
        content: Text('Apakah Anda yakin ingin menghapus ${p.nama} (NIK ${p.nik})? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await context.read<PendudukProvider>().deletePenduduk(p);
              if (!context.mounted) return;

              if (!result.handled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menghapus penduduk.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.queuedOffline
                      ? 'Penduduk akan dihapus saat online.'
                      : 'Penduduk berhasil dihapus.'),
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

  Widget _buildHeader(BuildContext context, PendudukModel p, Color genderColor, bool isMale) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [genderColor, genderColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: genderColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with gender icon
          Stack(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isMale ? Icons.male_rounded : Icons.female_rounded,
                      size: 24,
                      color: genderColor,
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: genderColor, width: 2),
                  ),
                  child: Text(
                    Helpers.getInitials(p.nama),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: genderColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            p.nama,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              p.genderLabel,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.badge_outlined, size: 14, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  p.nik,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primary),
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
            if (i < rows.length - 1)
              const Divider(height: 1, indent: 16, endIndent: 16),
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
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondaryOf(context),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimaryOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoYesNo(BuildContext context, String label, String? status, String? detail) {
    final isActive = status?.toUpperCase().trim() == 'Y' ||
        status?.toUpperCase().trim() == 'YA';
    final yesNoText = isActive ? 'Ya' : (status == null ? '-' : 'Tidak');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(color: AppTheme.textSecondaryOf(context), fontSize: 12),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.success.withValues(alpha: 0.1)
                        : AppTheme.textHintOf(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    yesNoText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppTheme.success : AppTheme.textHintOf(context),
                    ),
                  ),
                ),
                if (detail != null && detail.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    '/ $detail',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimaryOf(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
