import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/rekapitulasi_provider.dart';
import '../../models/rekapitulasi_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_display.dart';

class RekapitulasiScreen extends StatefulWidget {
  const RekapitulasiScreen({super.key});

  @override
  State<RekapitulasiScreen> createState() => _RekapitulasiScreenState();
}

class _RekapitulasiScreenState extends State<RekapitulasiScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadTab(0);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadTab(_tabController.index);
    }
  }

  void _loadTab(int index) {
    final prov = context.read<RekapitulasiProvider>();
    switch (index) {
      case 0:
        prov.loadDataUmum();
        break;
      case 1:
        prov.loadPokjaSatu();
        break;
      case 2:
        prov.loadPokjaDua();
        break;
      case 3:
        prov.loadPokjaTiga();
        break;
      case 4:
        prov.loadPokjaEmpat();
        break;
      case 5:
        prov.loadCatatan();
        break;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekapitulasi'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textHint,
          tabs: const [
            Tab(text: 'Data Umum'),
            Tab(text: 'Pokja 1'),
            Tab(text: 'Pokja 2'),
            Tab(text: 'Pokja 3'),
            Tab(text: 'Pokja 4'),
            Tab(text: 'Catatan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DataUmumTab(),
          _PokjaTab(index: 1),
          _PokjaTab(index: 2),
          _PokjaTab(index: 3),
          _PokjaTab(index: 4),
          _CatatanTab(),
        ],
      ),
    );
  }
}

class _DataUmumTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RekapitulasiProvider>();
    final cs = Theme.of(context).colorScheme;

    if (prov.isLoading) return const LoadingWidget();
    if (prov.error != null) return ErrorDisplay(error: prov.error, onRetry: () => prov.loadDataUmum());
    if (prov.dataUmum.isEmpty) return const EmptyState(icon: Icons.analytics_outlined, title: 'Belum ada data umum');

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () => prov.loadDataUmum(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: prov.dataUmum.length,
        itemBuilder: (context, index) {
          final d = prov.dataUmum[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
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
                      const Icon(Icons.location_on_outlined, color: AppTheme.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(d.dusun ?? 'Dusun ${index + 1}', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const Divider(height: 16),
                  _dataRow('Jumlah Keluarga', d.jumlahKeluarga ?? '0'),
                  _dataRow('Jumlah Penduduk', d.jumlahPenduduk ?? '0'),
                  _dataRow('Jumlah Kader', d.jumlahKader ?? '0'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PokjaTab extends StatelessWidget {
  final int index;

  const _PokjaTab({required this.index});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RekapitulasiProvider>();
    final cs = Theme.of(context).colorScheme;

    List<RekapitulasiModel> data;
    Future<void> Function() loadFn;

    switch (index) {
      case 2:
        data = prov.pokjaDua;
        loadFn = () => prov.loadPokjaDua();
        break;
      case 3:
        data = prov.pokjaTiga;
        loadFn = () => prov.loadPokjaTiga();
        break;
      case 4:
        data = prov.pokjaEmpat;
        loadFn = () => prov.loadPokjaEmpat();
        break;
      default:
        data = prov.pokjaSatu;
        loadFn = () => prov.loadPokjaSatu();
    }

    if (prov.isLoading) return const LoadingWidget();
    if (prov.error != null) return ErrorDisplay(error: prov.error, onRetry: loadFn);
    if (data.isEmpty) return const EmptyState(icon: Icons.folder_outlined, title: 'Belum ada data');

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: loadFn,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: data.length,
        itemBuilder: (context, i) {
          final item = data[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
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
                  if (item.dusun != null)
                    Text(item.dusun!, style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  if (item.kegiatan != null) ...[
                    const SizedBox(height: 4),
                    Text(item.kegiatan!, style: Theme.of(context).textTheme.titleMedium),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (item.volumeKegiatan != null) _detailChip('Vol', item.volumeKegiatan!),
                      if (item.jumlahSasaran != null) ...[const SizedBox(width: 6), _detailChip('Sasaran', item.jumlahSasaran!)],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _detailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
      child: Text('$label: $value', style: const TextStyle(fontSize: 11, color: AppTheme.primary)),
    );
  }
}

class _CatatanTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<RekapitulasiProvider>();
    final cs = Theme.of(context).colorScheme;

    if (prov.isLoading) return const LoadingWidget();
    if (prov.error != null) return ErrorDisplay(error: prov.error, onRetry: () => prov.loadCatatan());
    if (prov.catatanList.isEmpty) return const EmptyState(icon: Icons.baby_changing_station_rounded, title: 'Belum ada catatan');

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () => prov.loadCatatan(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: prov.catatanList.length,
        itemBuilder: (context, index) {
          final c = prov.catatanList[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (c.statusKematian != null ? AppTheme.error : AppTheme.success).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          c.statusKematian != null ? 'KEMATIAN' : (c.statusIbu ?? 'IBU').toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: c.statusKematian != null ? AppTheme.error : AppTheme.success,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Tahun ${c.configYear}', style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (c.namaIbu != null) ...[
                    Text('Ibu: ${c.namaIbu}', style: Theme.of(context).textTheme.titleMedium),
                  ],
                  if (c.namaBayi != null) ...[
                    const SizedBox(height: 2),
                    Text('Bayi: ${c.namaBayi}', style: const TextStyle(fontSize: 13)),
                  ],
                  if (c.namaMeninggal != null) ...[
                    const SizedBox(height: 2),
                    Text('Meninggal: ${c.namaMeninggal} (${c.sebabMeninggal ?? '-'})',
                        style: const TextStyle(fontSize: 13, color: AppTheme.error)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
