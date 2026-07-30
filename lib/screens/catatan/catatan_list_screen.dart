import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/catatan_provider.dart';
import '../../models/catatan_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_display.dart';
import '../../widgets/animations/page_transitions.dart';
import 'catatan_detail_screen.dart';
import 'catatan_form_screen.dart';

class CatatanListScreen extends StatefulWidget {
  const CatatanListScreen({super.key});

  @override
  State<CatatanListScreen> createState() => _CatatanListScreenState();
}

class _CatatanListScreenState extends State<CatatanListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatatanProvider>().loadCatatan(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CatatanProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            SlideTransitionRoute(page: const CatatanFormScreen()),
          );
          if (result == true) prov.loadCatatan(refresh: true);
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Tambah'),
      ),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 110,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: AppTheme.gradientHeader,
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Ibu & Anak',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Catatan Kelahiran & Kematian',
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),

          // Filter tabs
          SliverToBoxAdapter(
            child: _buildFilterTabs(context, prov),
          ),

          // Content
          prov.isLoading && prov.catatanList.isEmpty
              ? const SliverFillRemaining(child: LoadingWidget())
              : prov.error != null && prov.catatanList.isEmpty
                  ? SliverFillRemaining(
                      child: ErrorDisplay(error: prov.error, onRetry: () => prov.loadCatatan(refresh: true)),
                    )
                  : prov.filteredList.isEmpty
                      ? SliverFillRemaining(
                          child: EmptyState(
                            icon: Icons.baby_changing_station_rounded,
                            title: prov.filterStatus == 'all'
                                ? 'Belum ada catatan'
                                : 'Tidak ada catatan ${prov.filterStatus}',
                            subtitle: 'Tekan + untuk menambah catatan baru',
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final c = prov.filteredList[index];
                                return StaggeredListAnimation(
                                  index: index,
                                  child: _catatanCard(context, c),
                                );
                              },
                              childCount: prov.filteredList.length,
                            ),
                          ),
                        ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context, CatatanProvider prov) {
    final filters = [
      {'key': 'all', 'label': 'Semua', 'icon': Icons.all_inclusive_rounded},
      {'key': 'hamil', 'label': 'Hamil', 'icon': Icons.favorite_rounded},
      {'key': 'melahirkan', 'label': 'Melahirkan', 'icon': Icons.child_care_rounded},
      {'key': 'nifas', 'label': 'Nifas', 'icon': Icons.healing_rounded},
      {'key': 'death', 'label': 'Meninggal', 'icon': Icons.warning_amber_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final key = f['key'] as String;
            final isActive = prov.filterStatus == key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => prov.setFilter(key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? (key == 'death' ? AppTheme.error : AppTheme.primary).withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? (key == 'death' ? AppTheme.error : AppTheme.primary)
                          : AppTheme.border,
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        f['icon'] as IconData,
                        size: 16,
                        color: isActive
                            ? (key == 'death' ? AppTheme.error : AppTheme.primary)
                            : AppTheme.textHint,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        f['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive
                              ? (key == 'death' ? AppTheme.error : AppTheme.primary)
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _catatanCard(BuildContext context, CatatanKelahiranKematianModel c) {
    final isDeath = c.isDeath;

    // Determine card color based on status
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (isDeath) {
      statusColor = AppTheme.error;
      statusIcon = Icons.warning_amber_rounded;
      statusLabel = c.statusKematianLabel;
    } else if (c.statusIbu?.toLowerCase() == 'hamil') {
      statusColor = AppTheme.female;
      statusIcon = Icons.favorite_rounded;
      statusLabel = 'Ibu Hamil';
    } else if (c.statusIbu?.toLowerCase() == 'melahirkan') {
      statusColor = AppTheme.success;
      statusIcon = Icons.child_care_rounded;
      statusLabel = 'Melahirkan';
    } else if (c.statusIbu?.toLowerCase() == 'nifas') {
      statusColor = AppTheme.info;
      statusIcon = Icons.healing_rounded;
      statusLabel = 'Masa Nifas';
    } else {
      statusColor = AppTheme.textHint;
      statusIcon = Icons.help_outline_rounded;
      statusLabel = c.statusIbu ?? '-';
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CatatanDetailScreen(catatanId: c.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDeath ? AppTheme.error.withOpacity(0.3) : statusColor.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Status icon badge
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, size: 18, color: statusColor),
                ),
                const SizedBox(width: 10),
                // Status & year
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        'Tahun ${c.configYear}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                      ),
                    ],
                  ),
                ),
                // Arrow
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint, size: 20),
              ],
            ),

            const SizedBox(height: 10),

            // Ibu info
            if (c.namaIbu != null) ...[
              Row(
                children: [
                  const Icon(Icons.person_rounded, size: 14, color: AppTheme.textHint),
                  const SizedBox(width: 6),
                  Text('Ibu: ', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  Expanded(
                    child: Text(
                      c.namaIbu!,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            if (c.namaSuami != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_rounded, size: 14, color: AppTheme.textHint),
                  const SizedBox(width: 6),
                  Text('Suami: ', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  Expanded(
                    child: Text(
                      c.namaSuami!,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Baby info
            if (c.hasBaby) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.child_care_rounded, size: 14, color: AppTheme.success),
                    const SizedBox(width: 4),
                    Text(
                      c.namaBayi!,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.success),
                    ),
                    if (c.tanggalLahirBayi != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '(${c.tanggalLahirBayi})',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Death info
            if (isDeath) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: AppTheme.error),
                    const SizedBox(width: 4),
                    Text(
                      '${c.statusKematianLabel}: ${c.namaMeninggal ?? "-"}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.error),
                    ),
                  ],
                ),
              ),
            ],

            // Kelompok
            if (c.namaKelompok != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.groups_outlined, size: 12, color: AppTheme.textHint),
                  const SizedBox(width: 4),
                  Text(
                    c.kelompokDisplay,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
