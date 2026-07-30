import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/dasawisma_provider.dart';
import '../../providers/reference_provider.dart';
import '../../models/dasawisma_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_display.dart';
import '../../widgets/animations/page_transitions.dart';
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
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<DasawismaProvider>();
      prov.loadKelompok(refresh: true);
      prov.loadRingkasan();
      prov.loadRecapKesehatan();
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
          : _tabController.index == 2
              ? FloatingActionButton.extended(
                  onPressed: () => Navigator.of(context).push(
                    SlideTransitionRoute(page: const DasawismaKeluargaFormScreen()),
                  ).then((r) {
                    if (r == true) prov.loadRecapKesehatan();
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
            expandedHeight: 110,
            pinned: true,
            floating: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: AppTheme.gradientHeader,
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Dasawisma', style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Data kelompok & kesehatan', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.6),
              onTap: (_) => setState(() {}),
              tabs: const [
                Tab(icon: Icon(Icons.groups_rounded, size: 20), text: 'Kelompok'),
                Tab(icon: Icon(Icons.analytics_rounded, size: 20), text: 'Ringkasan'),
                Tab(icon: Icon(Icons.health_and_safety_rounded, size: 20), text: 'Kesehatan'),
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
          // Filter dusun
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('Semua', prov.filterDusunId == null, () => prov.setFilterDusun(null)),
                    ...?refs?.dusun.map((d) => _filterChip(d.nama, prov.filterDusunId == d.id, () => prov.setFilterDusun(d.id))),
                  ],
                ),
              ),
            ),
          ),
          // List kelompok
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

  Widget _filterChip(String label, bool isActive, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? AppTheme.primary : AppTheme.border),
          ),
          child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? AppTheme.primary : AppTheme.textSecondary)),
        ),
      ),
    );
  }
}

Widget _kelompokCard(BuildContext context, KelompokDasawismaModel k, void Function(KelompokDasawismaModel)? onTap) {
  return GestureDetector(
    onTap: () => onTap?.call(k),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.groups_rounded, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(k.nama, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (k.dusun != null) ...[
                      const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textHint),
                      const SizedBox(width: 4),
                      Text(k.dusun!, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                      const SizedBox(width: 10),
                    ],
                    if (k.namaKader != null) ...[
                      const Icon(Icons.person_outline, size: 12, color: AppTheme.textHint),
                      const SizedBox(width: 4),
                      Text(k.namaKader!, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (k.totalKeluarga != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('${k.totalKeluarga} KK', style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint, size: 20),
        ],
      ),
    ),
  );
}

// ======================== RINGKASAN TAB ========================

class _RingkasanTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DasawismaProvider>();

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
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
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
                    backgroundColor: AppTheme.primary.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary.withOpacity(0.5)),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text('$value $label', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

// ======================== KESEHATAN TAB ========================

class _KesehatanTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DasawismaProvider>();

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
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.health_and_safety_rounded, color: AppTheme.success, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(k.kelompok ?? 'Kelompok ${index + 1}', style: Theme.of(context).textTheme.titleMedium),
                            if (k.dusun != null) Text(k.dusun!, style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
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
                      _healthIndicator('Balita', k.totalBalita, Icons.child_care_rounded, Colors.orange),
                      _healthIndicator('Bumil', k.ibuHamil, Icons.favorite_rounded, AppTheme.female),
                      _healthIndicator('Stunting', k.stunting, Icons.warning_rounded, AppTheme.error),
                      _healthIndicator('Lansia', k.lansia, Icons.elderly_rounded, AppTheme.info),
                    ],
                  ),
                  if (k.ibuMenyusui > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _healthIndicator('Menyusui', k.ibuMenyusui, Icons.child_friendly_rounded, AppTheme.success),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _healthIndicator(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text('$value', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }
}
