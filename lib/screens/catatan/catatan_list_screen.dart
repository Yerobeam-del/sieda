import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/catatan_provider.dart';
import '../../models/catatan_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_display.dart';
import '../../widgets/animations/page_transitions.dart';
import '../../widgets/pending_sync_badge.dart';
import '../../widgets/header_search_field.dart';
import '../../widgets/filter_chip_bar.dart';
import 'catatan_detail_screen.dart';

class CatatanListScreen extends StatefulWidget {
  const CatatanListScreen({super.key});

  @override
  State<CatatanListScreen> createState() => _CatatanListScreenState();
}

class _CatatanListScreenState extends State<CatatanListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Rebuild agar tombol clear (✕) muncul/hilang saat mengetik.
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatatanProvider>().loadCatatan(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CatatanProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            // Inset-aware: status bar + top pad + title block + bottom pad.
            expandedHeight: MediaQuery.paddingOf(context).top + 96,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: AppTheme.gradientHeaderOf(context),
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.paddingOf(context).top + 24,
                  20,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Ibu & Anak',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Catatan Kelahiran & Kematian',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),

          // Filter tabs + pencarian + tahun
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildFilterTabs(context, prov),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: HeaderSearchField(
                    controller: _searchController,
                    hintText: 'Cari nama ibu, suami, bayi...',
                    onChanged: prov.setSearch,
                  ),
                ),
                if (prov.availableYears.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: FilterChipBar<int?>(
                      options: [
                        (label: 'Semua Tahun', value: null),
                        ...prov.availableYears
                            .map((y) => (label: '$y', value: y)),
                      ],
                      selected: prov.filterTahun,
                      onSelected: prov.setFilterTahun,
                    ),
                  ),
                const SizedBox(height: 4),
              ],
            ),
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
                            title: prov.hasActiveFilter
                                ? 'Tidak ada catatan yang cocok'
                                : 'Belum ada catatan',
                            subtitle: prov.hasActiveFilter
                                ? 'Coba ubah filter atau kata kunci'
                                : 'Tekan + untuk menambah catatan baru',
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
                        ? (key == 'death' ? AppTheme.error : AppTheme.primary).withValues(alpha: 0.1)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? (key == 'death' ? AppTheme.error : AppTheme.primary)
                          : AppTheme.borderOf(context),
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
                            : AppTheme.textHintOf(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        f['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isActive
                              ? (key == 'death' ? AppTheme.error : AppTheme.primary)
                              : AppTheme.textSecondaryOf(context),
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
      statusColor = AppTheme.textHintOf(context);
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
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDeath ? AppTheme.error.withValues(alpha: 0.3) : statusColor.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
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
                    color: statusColor.withValues(alpha: 0.1),
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (c.isPendingSync) ...[
                            const SizedBox(width: 8),
                            const PendingSyncBadge(),
                          ],
                        ],
                      ),
                      Text(
                        'Tahun ${c.configYear}',
                        style: TextStyle(fontSize: 11, color: AppTheme.textHintOf(context)),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(Icons.chevron_right_rounded, color: AppTheme.textHintOf(context), size: 20),
              ],
            ),

            const SizedBox(height: 10),

            // Ibu info
            if (c.namaIbu != null) ...[
              Row(
                children: [
                  Icon(Icons.person_rounded, size: 14, color: AppTheme.textHintOf(context)),
                  const SizedBox(width: 6),
                  Text('Ibu: ', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context))),
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
                  Icon(Icons.person_rounded, size: 14, color: AppTheme.textHintOf(context)),
                  const SizedBox(width: 6),
                  Text('Suami: ', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryOf(context))),
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
                  color: AppTheme.success.withValues(alpha: 0.08),
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
                        style: TextStyle(fontSize: 11, color: AppTheme.textHintOf(context)),
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
                  color: AppTheme.error.withValues(alpha: 0.08),
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
                  Icon(Icons.groups_outlined, size: 12, color: AppTheme.textHintOf(context)),
                  const SizedBox(width: 4),
                  Text(
                    c.kelompokDisplay,
                    style: TextStyle(fontSize: 11, color: AppTheme.textHintOf(context)),
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
