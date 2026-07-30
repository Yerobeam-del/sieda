import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/penduduk_model.dart';
import '../../providers/penduduk_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_display.dart';

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
      appBar: AppBar(title: const Text('Detail Penduduk')),
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
            _infoRow('No. Registrasi', p.noRegistrasi ?? '-'),
            _infoRow('NIK', p.nik),
            _infoRow('Nama Lengkap', p.nama),
            _infoRow('Tempat, Tgl Lahir', p.formattedTtl),
            _infoRow('Usia', p.usiaLabel),
            _infoRow('Jenis Kelamin', p.genderLabel),
            _infoRow('Agama', p.agama ?? '-'),
            _infoRow('Pendidikan', p.pendidikan ?? '-'),
            _infoRow('Pekerjaan', p.pekerjaan ?? '-'),
            _infoRow('No. HP', Helpers.formatPhone(p.noHp)),
            _infoRow('Alamat', p.alamat ?? '-'),
          ]),
          const SizedBox(height: 16),

          // ============ STATUS KELUARGA ============
          _sectionTitle(context, Icons.family_restroom_rounded, 'Status Keluarga'),
          const SizedBox(height: 8),
          _infoCard(context, [
            _infoRow('Status Perkawinan', p.statusPerkawinan ?? '-'),
            _infoRow('Peran dalam Keluarga', p.peranKeluarga ?? '-'),
            _infoRow('Status dalam Keluarga', p.statusKeluarga ?? '-'),
          ]),
          const SizedBox(height: 16),

          // ============ PROGRAM PKK ============
          _sectionTitle(context, Icons.health_and_safety_rounded, 'Program PKK'),
          const SizedBox(height: 8),
          _infoCard(context, [
            _infoYesNo('Akseptor KB', p.statusAkseptor, p.jenisAkseptor),
            _infoYesNo('Posyandu', p.statusPosyandu, 
                p.frekuensiPosyandu != null ? '${p.frekuensiPosyandu}/${p.satuanFrekuensiVolume ?? "-"}' : null),
            _infoYesNo('BKB (Bina Keluarga Balita)', p.statusPbkb, null),
            _infoYesNo('Memiliki Tabungan', p.statusTabungan, null),
            _infoYesNo('Kelompok Belajar', p.statusKelompokBelajar, p.jenisKelompokBelajar),
            _infoYesNo('PAUD/Sejenis', p.statusPaud, null),
            _infoYesNo('Kegiatan Koperasi', p.statusKegiatanKoperasi, p.jenisKoperasi),
            _infoYesNo('Kebutuhan Khusus', p.statusKebutuhanKhusus, p.kebutuhanKhusus),
          ]),
          const SizedBox(height: 32),
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
          colors: [genderColor, genderColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: genderColor.withOpacity(0.3),
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
              color: Colors.white.withOpacity(0.2),
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
              color: Colors.white.withOpacity(0.15),
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
            color: AppTheme.primary.withOpacity(0.1),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoYesNo(String label, String? status, String? detail) {
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
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.success.withOpacity(0.1)
                        : AppTheme.textHint.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    yesNoText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppTheme.success : AppTheme.textHint,
                    ),
                  ),
                ),
                if (detail != null && detail.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    '/ $detail',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
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
