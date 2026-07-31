import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/dasawisma_provider.dart';
import '../../providers/reference_provider.dart';
import '../../models/dasawisma_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_display.dart';
import '../../widgets/animations/page_transitions.dart';
import '../../widgets/pending_sync_badge.dart';
import 'dasawisma_form_screen.dart';
import 'dasawisma_keluarga_form_screen.dart';
import 'dasawisma_detail_screen.dart';

class DasawismaScreen extends StatefulWidget {
  const DasawismaScreen({super.key});

  @override
  State<DasawismaScreen> createState() => _DasawismaScreenState();
}

class _DasawismaScreenState extends State<DasawismaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<DasawismaProvider>();
      prov.loadKelompok(refresh: true);
      prov.loadRingkasan();
      prov.loadRecapKesehatan();
      prov.loadDasawismaKeluarga();
      context.read<ReferenceProvider>().loadReferences();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DasawismaProvider>();

    return Scaffold(
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  SlideTransitionRoute(page: const DasawismaKelompokFormScreen()),
                );
                if (result == true) prov.loadKelompok(refresh: true);
              },
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Kelompok'),
            )
          : _tabController.index == 3
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.of(context).push(
                    SlideTransitionRoute(page: const DasawismaKeluargaFormScreen()),
                  ).then((r) {
                    if (r == true) prov.loadDasawismaKeluarga();
                  }),
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Data Kesehatan'),
                )
              : null,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            // Inset + top pad + title block + 72px TabBar + slack.
            expandedHeight: MediaQuery.paddingOf(context).top + 152,
            pinned: true,
            floating: true,
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
                      'Dasawisma',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Data kelompok & kesehatan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14),
                    ),
                    // Reserve space for the TabBar below so the title stays
                    // above it instead of being hidden behind it.
                    const SizedBox(height: 72),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
              onTap: (_) => setState(() {}),
              tabs: const [
                Tab(icon: Icon(Icons.groups_rounded, size: 20), text: 'Kelompok'),
                Tab(icon: Icon(Icons.analytics_rounded, size: 20), text: 'Ringkasan'),
                Tab(icon: Icon(Icons.health_and_safety_rounded, size: 20), text: 'Kesehatan'),
                Tab(icon: Icon(Icons.family_restroom_rounded, size: 20), text: 'Keluarga'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _KelompokTab(onKelompokTap: (k) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => KelompokDetailScreen(kelompokId: k.id),
              )).then((_) => prov.loadKelompok(refresh: true));
            }),
            _RingkasanTab(),
            _KesehatanTab(),
            _KeluargaTab(),
          ],
        ),
      ),
    );
  }
}

// ======================== KELOMPOK TAB ========================

class _KelompokTab extends StatelessWidget {
  final void Function(KelompokDasawismaModel)? onKelompokTap;

  const _KelompokTab({this.onKelompokTap});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DasawismaProvider>();
    final refProv = context.watch<ReferenceProvider>();
    final refs = refProv.data;

    if (prov.isLoading && prov.kelompokList.isEmpty) {
      return const LoadingWidget();
    }
    if (prov.error != null && prov.kelompokList.isEmpty) {
      return ErrorDisplay(error: prov.error, onRetry: () => prov.loadKelompok(refresh: true));
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () => prov.loadKelompok(refresh: true),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(context, 'Semua', prov.filterDusunId == null, () => prov.setFilterDusun(null)),
                    ...?refs?.dusun.map((d) => _filterChip(context, d.nama, prov.filterDusunId == d.id, () => prov.setFilterDusun(d.id))),
                  ],
                ),
              ),
            ),
          ),
          prov.kelompokList.isEmpty
              ? SliverFillRemaining(
                  child: EmptyState(icon: Icons.groups_outlined, title: 'Belum ada kelompok', subtitle: 'Tekan + untuk menambah'),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final k = prov.kelompokList[index];
                        return StaggeredListAnimation(
                          index: index,
                          child: _kelompokCard(context, k, onKelompokTap),
                        );
                      },
                      childCount: prov.kelompokList.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, String label, bool isActive, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? AppTheme.primary : AppTheme.borderOf(context)),
          ),
          child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? AppTheme.primary : AppTheme.textSecondaryOf(context))),
        ),
      ),
    );
  }
}

Widget _kelompokCard(BuildContext context, KelompokDasawismaModel k, void Function(KelompokDasawismaModel)? onTap) {
  final cs = Theme.of(context).colorScheme;
  return GestureDetector(
    onTap: () => onTap?.call(k),
    child: Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.groups_rounded, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          k.nama,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (k.isPendingSync) ...[
                        const SizedBox(width: 8),
                        const PendingSyncBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (k.dusun != null) ...[
                        Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textHintOf(context)),
                        const SizedBox(width: 4),
                        Text(k.dusun!, style: TextStyle(fontSize: 11, color: AppTheme.textHintOf(context))),
                        const SizedBox(width: 10),
                      ],
                      if (k.namaKader != null) ...[
                        Icon(Icons.person_outline, size: 12, color: AppTheme.textHintOf(context)),
                        const SizedBox(width: 4),
                        Text(k.namaKader!, style: TextStyle(fontSize: 11, color: AppTheme.textHintOf(context))),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (k.totalKeluarga != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${k.totalKeluarga} KK', style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textHintOf(context), size: 20),
          ],
        ),
      ),
    ),
  );
}

// ======================== RINGKASAN TAB ========================

class _RingkasanTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DasawismaProvider>();
    final cs = Theme.of(context).colorScheme;

    if (prov.isLoading && prov.ringkasanList.isEmpty) return const LoadingWidget();
    if (prov.ringkasanList.isEmpty) return const EmptyState(icon: Icons.analytics_outlined, title: 'Belum ada data ringkasan');

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () => prov.loadRingkasan(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: prov.ringkasanList.length,
        itemBuilder: (context, index) {
          final r = prov.ringkasanList[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      ),
                      const SizedBox(width: 10),
                      Text(r.dusun, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _chip('${r.totalKelompok}', 'Kelompok', AppTheme.primary),
                      const SizedBox(width: 8),
                      _chip('${r.totalKeluarga}', 'KK', AppTheme.info),
                      const SizedBox(width: 8),
                      _chip('${r.totalPenduduk}', 'Jiwa', AppTheme.success),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: prov.ringkasanList.isNotEmpty ? (r.totalKeluarga / (prov.ringkasanList.map((e) => e.totalKeluarga).reduce((a, b) => a > b ? a : b)).toDouble()) : 0,
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary.withValues(alpha: 0.5)),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text('$value $label', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

// ======================== KESEHATAN TAB ========================

class _KesehatanTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DasawismaProvider>();
    final cs = Theme.of(context).colorScheme;

    if (prov.isLoading && prov.recapKesehatanList.isEmpty) return const LoadingWidget();
    if (prov.recapKesehatanList.isEmpty) return const EmptyState(icon: Icons.health_and_safety_outlined, title: 'Belum ada data kesehatan');

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () => prov.loadRecapKesehatan(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: prov.recapKesehatanList.length,
        itemBuilder: (context, index) {
          final k = prov.recapKesehatanList[index];
          return StaggeredListAnimation(
            index: index,
            child: Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.health_and_safety_rounded, color: AppTheme.success, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      k.kelompok ?? 'Kelompok ${index + 1}',
                                      style: Theme.of(context).textTheme.titleMedium,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (k.isPendingSync) ...[
                                    const SizedBox(width: 8),
                                    const PendingSyncBadge(),
                                  ],
                                ],
                              ),
                              if (k.dusun != null) Text(k.dusun!, style: TextStyle(fontSize: 11, color: AppTheme.textHintOf(context))),
                            ],
                          ),
                        ),
                        Text('${k.totalKeluarga} KK', style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _healthIndicator(context, 'Balita', k.totalBalita, Icons.child_care_rounded, Colors.orange),
                        _healthIndicator(context, 'Bumil', k.ibuHamil, Icons.favorite_rounded, AppTheme.female),
                        _healthIndicator(context, 'Stunting', k.stunting, Icons.warning_rounded, AppTheme.error),
                        _healthIndicator(context, 'Lansia', k.lansia, Icons.elderly_rounded, AppTheme.info),
                      ],
                    ),
                    if (k.ibuMenyusui > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _healthIndicator(context, 'Menyusui', k.ibuMenyusui, Icons.child_friendly_rounded, AppTheme.success),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _healthIndicator(BuildContext context, String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text('$value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        Text(label, style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryOf(context))),
      ],
    );
  }
}

// ======================== KELUARGA TAB (FORM DASAWISMA KELUARGA) ========================

class _KeluargaTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DasawismaProvider>();
    final cs = Theme.of(context).colorScheme;

    if (prov.isLoading && prov.dasawismaKeluargaList.isEmpty) return const LoadingWidget();
    if (prov.error != null && prov.dasawismaKeluargaList.isEmpty) {
      return ErrorDisplay(error: prov.error, onRetry: () => prov.loadDasawismaKeluarga());
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () => prov.loadDasawismaKeluarga(),
      child: prov.dasawismaKeluargaList.isEmpty
          ? const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 500,
                child: EmptyState(
                  icon: Icons.family_restroom_outlined,
                  title: 'Belum ada data keluarga',
                  subtitle: 'Tekan + untuk mengisi data kesehatan keluarga',
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: prov.dasawismaKeluargaList.length,
              itemBuilder: (context, index) {
                final d = prov.dasawismaKeluargaList[index];
                return StaggeredListAnimation(
                  index: index,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.family_restroom_rounded, color: AppTheme.success, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'No. KK: ${d.noKK}',
                                            style: Theme.of(context).textTheme.titleMedium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (d.isPendingSync) ...[
                                          const SizedBox(width: 8),
                                          const PendingSyncBadge(),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 4,
                                      children: [
                                        _kecil(context, 'Balita ${d.jumlahBalita ?? 0}'),
                                        _kecil(context, 'Bumil ${d.jumlahIbuHamil ?? 0}'),
                                        _kecil(context, 'Lansia ${d.jumlahLansia ?? 0}'),
                                        if (d.makananPokok != null) _kecil(context, 'Makanan: ${d.makananPokok}'),
                                        if (d.sumberAir != null) _kecil(context, 'Air: ${d.sumberAir}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 4),
                              _actionButton(context, prov, d),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _kecil(BuildContext context, String label) {
    return Text(label, style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context)));
  }

  Widget _actionButton(BuildContext context, DasawismaProvider prov, DasawismaKeluargaData d) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: AppTheme.textHintOf(context), size: 20),
      onSelected: (value) async {
        if (value == 'edit') {
          final result = await Navigator.of(context).push(SlideTransitionRoute(
            page: DasawismaKeluargaFormScreen(data: d),
          ));
          if (result == true) prov.loadDasawismaKeluarga();
        } else if (value == 'delete') {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Hapus Data?'),
              content: Text('Hapus data kesehatan keluarga No. KK ${d.noKK}?'),
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
          if (confirmed == true) {
            final ok = await prov.deleteDasawismaKeluarga(d.noKK);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? 'Data berhasil dihapus' : 'Gagal menghapus data'),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(16),
              ));
            }
          }
        }
      },
      itemBuilder: (ctx) => const [
        PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')])),
        PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: Colors.red))])),
      ],
    );
  }
}
