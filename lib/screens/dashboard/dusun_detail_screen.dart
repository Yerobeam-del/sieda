import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dashboard_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_display.dart';
import '../../widgets/animations/page_transitions.dart';

/// Detail satu dusun: menampilkan seluruh dasawisma/kelompok di dalamnya
/// beserta rincian KK, jiwa, dan komposisi gender per kelompok.
class DusunDetailScreen extends StatefulWidget {
  final int dusunId;
  final String dusunName;

  const DusunDetailScreen({
    super.key,
    required this.dusunId,
    required this.dusunName,
  });

  @override
  State<DusunDetailScreen> createState() => _DusunDetailScreenState();
}

class _DusunDetailScreenState extends State<DusunDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDetailDusun(widget.dusunId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DashboardProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dusunName),
      ),
      body: prov.isLoading && prov.detailDusun == null
          ? const LoadingWidget(message: 'Memuat detail dusun...')
          : prov.error != null && prov.detailDusun == null
              ? ErrorDisplay(
                  error: prov.error,
                  onRetry: () => prov.loadDetailDusun(widget.dusunId),
                )
              : prov.detailDusun == null
                  ? const EmptyState(
                      icon: Icons.location_off_rounded,
                      title: 'Detail dusun tidak ditemukan',
                    )
                  : _buildContent(context, prov.detailDusun!),
    );
  }

  Widget _buildContent(BuildContext context, DetailDusun detailDusun) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final kelompokList = detailDusun.detail;
    final totalKeluarga = kelompokList.fold<int>(
        0, (sum, k) => sum + k.totalKeluarga);
    final totalPenduduk = kelompokList.fold<int>(
        0, (sum, k) => sum + k.totalPenduduk);
    final totalLakiLaki =
        kelompokList.fold<int>(0, (sum, k) => sum + k.lakiLaki);
    final totalPerempuan =
        kelompokList.fold<int>(0, (sum, k) => sum + k.perempuan);

    final lakiPercent = totalPenduduk > 0
        ? (totalLakiLaki / totalPenduduk * 100)
        : 0.0;
    final perempuanPercent = totalPenduduk > 0
        ? (totalPerempuan / totalPenduduk * 100)
        : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Header ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.gradientHeaderOf(context).copyWith(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.dusunName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${kelompokList.length} dasawisma',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Ringkasan angka di header
              Row(
                children: [
                  _headerStat(context, 'KK', totalKeluarga.toString()),
                  const SizedBox(width: 12),
                  _headerStat(context, 'Jiwa', totalPenduduk.toString()),
                  const SizedBox(width: 12),
                  _headerStat(context, 'Laki-laki', totalLakiLaki.toString()),
                  const SizedBox(width: 12),
                  _headerStat(context, 'Perempuan', totalPerempuan.toString()),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Gender ratio bar ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Komposisi Gender',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${lakiPercent.toStringAsFixed(1)}% : ${perempuanPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (lakiPercent * 100).toInt().clamp(1, 100),
                        child: Container(color: AppTheme.male),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: (perempuanPercent * 100).toInt().clamp(1, 100),
                        child: Container(color: AppTheme.female),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Judul list dasawisma ──
        Row(
          children: [
            Icon(Icons.groups_rounded, color: cs.primary, size: 20),
            const SizedBox(width: 8),
            Text('Dasawisma di Dusun Ini', style: theme.textTheme.titleLarge),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${kelompokList.length} kelompok',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (kelompokList.isEmpty)
          const EmptyState(
            icon: Icons.groups_outlined,
            title: 'Belum ada dasawisma di dusun ini',
          )
        else
          ...kelompokList.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: StaggeredListAnimation(
                  index: entry.key,
                  child: _kelompokCard(context, entry.value),
                ),
              )),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Stat kecil di header gradient.
  Widget _headerStat(BuildContext context, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu satu dasawisma/kelompok.
  Widget _kelompokCard(BuildContext context, DetailKelompok kelompok) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final totalPenduduk = kelompok.totalPenduduk;
    final lakiLaki = kelompok.lakiLaki;
    final perempuan = kelompok.perempuan;
    final lakiPercent =
        totalPenduduk > 0 ? (lakiLaki / totalPenduduk * 100) : 0.0;
    final perempuanPercent =
        totalPenduduk > 0 ? (perempuan / totalPenduduk * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${kelompok.id}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kelompok.kelompok,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${kelompok.totalKeluarga} KK · ${kelompok.totalPenduduk} Jiwa',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mini gender bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: (lakiPercent * 100).toInt().clamp(1, 100),
                    child: Container(color: AppTheme.male),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (perempuanPercent * 100).toInt().clamp(1, 100),
                    child: Container(color: AppTheme.female),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '♂ $lakiLaki (${lakiPercent.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.male,
                ),
              ),
              Text(
                '♀ $perempuan (${perempuanPercent.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.female,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
