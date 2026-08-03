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
import '../../models/dasawisma_model.dart';
import '../../models/reference_model.dart';
import '../../providers/dasawisma_provider.dart';
import '../../providers/reference_provider.dart';
import '../dasawisma/dasawisma_keluarga_form_screen.dart';
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

          // Dasawisma Keluarga — lihat/isi/edit/hapus.
          _sectionTitle('Dasawisma Keluarga'),
          const SizedBox(height: 8),
          _dasawismaKeluargaSection(context, k.dasawismaKeluarga),
          const SizedBox(height: 16),

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

  /// Section Dasawisma Keluarga — mirror halaman
  /// `/dasawisma-keluarga/show/{no_kk}` di website: tampilkan semua field,
  /// plus aksi isi/edit dan hapus (dengan dukungan offline).
  Widget _dasawismaKeluargaSection(BuildContext context, dynamic dkRaw) {
    final refs = context.watch<ReferenceProvider>().data;
    final dk = dkRaw as DasawismaKeluargaData?;
    if (dk == null) return _dasawismaKeluargaEmpty(context);

    final jenisMakanan = _refName(refs?.jenisMakananPokok, dk.idJenisMakananPokok);
    final jenisUsaha = _refName(refs?.jenisUsahaUp2k, dk.idJenisUsahaUp2k);
    final sumberAir = dk.sumberAir ?? _refName(refs?.sumberAir, dk.idSumberAir);

    // Nilai baris boleh null (difilter di bawah); pakai record nullable
    // agar _fmt()/ternary yang mengembalikan String? cocok dengan tipe.
    final groups = <String, List<(String, String?)>>{
      'Keluarga': [
        ('Jumlah Anggota (KK)', _fmt(dk.jumlahKK)),
        ('Balita Laki-laki', _fmt(dk.jumlahBalitaLakiLaki)),
        ('Balita Perempuan', _fmt(dk.jumlahBalitaPerempuan)),
        ('Total Balita', _fmt(dk.jumlahBalita)),
      ],
      'PUS & WUS': [
        ('PUS', _fmt(dk.jumlahPus)),
        ('WUS', _fmt(dk.jumlahWus)),
        ('Buta', _fmt(dk.jumlahButa)),
        ('Ibu Hamil', _fmt(dk.jumlahIbuHamil)),
        ('Ibu Menyusui', _fmt(dk.jumlahIbuMenyusui)),
        ('Lansia', _fmt(dk.jumlahLansia)),
      ],
      'Gizi & Kesehatan': [
        ('Gizi Kurang', _fmt(dk.jumlahGiziKurang)),
        ('Gizi Buruk', _fmt(dk.jumlahGiziBuruk)),
        ('Stunting', _fmt(dk.jumlahStunting)),
        ('Disabilitas', _fmt(dk.jumlahDisabilitas)),
      ],
      'Makanan Pokok': [
        ('Makanan Pokok', dk.makananPokok),
        ('Jenis Makanan Pokok', jenisMakanan == '-' ? null : jenisMakanan),
      ],
      'Sanitasi & Rumah': [
        ('Jamban Keluarga', dk.statusJamban),
        ('Jumlah Jamban', _fmt(dk.jumlahJamban)),
        ('Sumber Air', sumberAir == '-' ? null : sumberAir),
        ('Tempat Sampah', dk.statusTempatPembuanganSampah),
        ('Saluran Pembuangan', dk.statusSaluranPembuangan),
        ('Stiker P4K', dk.statusStickerP4k),
        ('Kriteria Rumah', dk.kriteriaRumah),
      ],
      'UP2K & KUKL': [
        ('Aktivitas UP2K', dk.statusAktifitasUp2k),
        ('Jenis Usaha UP2K', jenisUsaha == '-' ? null : jenisUsaha),
        ('Aktivitas KUKL', dk.statusAktifitasKukl),
      ],
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.health_and_safety_rounded, color: AppTheme.success, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dasawisma Keluarga', style: Theme.of(context).textTheme.titleSmall),
                      Text('Tahun ${dk.configYear}', style: TextStyle(fontSize: 11, color: AppTheme.textHintOf(context))),
                    ],
                  ),
                ),
                if (dk.isPendingSync) const Padding(padding: EdgeInsets.only(right: 6), child: PendingSyncBadge()),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit Dasawisma Keluarga',
                  onPressed: () => _openDasawismaKeluargaForm(data: dk),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.error),
                  tooltip: 'Hapus Dasawisma Keluarga',
                  onPressed: () => _confirmDeleteDasawismaKesehatan(dk),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _healthItem(context, 'Balita', '${dk.jumlahBalita ?? 0}', Colors.orange),
                _healthItem(context, 'Bumil', '${dk.jumlahIbuHamil ?? 0}', AppTheme.female),
                _healthItem(context, 'Stunting', '${dk.jumlahStunting ?? 0}', AppTheme.error),
                _healthItem(context, 'Lansia', '${dk.jumlahLansia ?? 0}', AppTheme.info),
              ],
            ),
            const Divider(height: 24),
            for (final entry in groups.entries)
              if (entry.value.any((r) => r.$2 != null)) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                ...entry.value.where((r) => r.$2 != null).map((r) => _detailRow(context, r.$1, r.$2!)),
              ],
          ],
        ),
      ),
    );
  }

  Widget _dasawismaKeluargaEmpty(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.health_and_safety_outlined, color: AppTheme.success, size: 28),
            ),
            const SizedBox(height: 10),
            Text('Belum ada data kesehatan keluarga', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Isi data Dasawisma Keluarga untuk melengkapi profil kesehatan keluarga ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context)),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _openDasawismaKeluargaForm(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Isi Dasawisma Keluarga'),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.success),
            ),
          ],
        ),
      ),
    );
  }

  void _openDasawismaKeluargaForm({DasawismaKeluargaData? data}) {
    // Tangkap provider sebelum async gap agar tidak ada BuildContext dipakai
    // di callback .then() (lint-safe).
    final prov = context.read<KeluargaProvider>();
    Navigator.of(context).push(
      SlideTransitionRoute(
        page: DasawismaKeluargaFormScreen(
          initialNoKK: data?.noKK ?? widget.noKk,
          data: data,
        ),
      ),
    ).then((_) {
      // Selalu muat ulang setelah kembali agar data kesehatan terbaru tampil.
      prov.loadDetail(widget.noKk);
    });
  }

  Future<void> _confirmDeleteDasawismaKesehatan(DasawismaKeluargaData dk) async {
    final dasawismaProv = context.read<DasawismaProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Dasawisma Keluarga?'),
        content: Text('Hapus data Dasawisma Keluarga untuk No. KK ${dk.noKK}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await dasawismaProv.deleteDasawismaKeluarga(dk.noKK);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Data kesehatan berhasil dihapus.' : 'Gagal menghapus data kesehatan.'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
    context.read<KeluargaProvider>().loadDetail(widget.noKk);
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(label, style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context))),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  String? _fmt(int? v) => v == null ? null : '$v';

  String _refName(List<ReferenceItem>? items, int? id) {
    if (items == null || id == null) return '-';
    for (final r in items) {
      if (r.id == id) return r.nama;
    }
    return '-';
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
