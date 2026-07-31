import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/keluarga_provider.dart';
import '../../models/keluarga_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_display.dart';
import '../../widgets/animations/page_transitions.dart';
import '../../widgets/pending_sync_badge.dart';
import '../../widgets/header_search_field.dart';
import '../../widgets/filter_chip_bar.dart';
import 'keluarga_detail_screen.dart';

class KeluargaListScreen extends StatefulWidget {
  const KeluargaListScreen({super.key});

  @override
  State<KeluargaListScreen> createState() => _KeluargaListScreenState();
}

class _KeluargaListScreenState extends State<KeluargaListScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  /// Kontrol scroll list — untuk indikator posisi di header.
  final ScrollController _scrollController = ScrollController();

  /// Progres scroll (0..1): seberapa jauh user berada di dalam list.
  final ValueNotifier<double> _scrollProgress = ValueNotifier(0);

  /// Animates the header height in sync with the search field so the
  /// expandedHeight never overflows its content while toggling.
  late final AnimationController _headerAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  @override
  void initState() {
    super.initState();
    // Rebuild so the clear (✕) button appears/disappears while typing.
    _searchController.addListener(() => setState(() {}));
    _scrollController.addListener(_updateScrollProgress);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KeluargaProvider>().loadKeluarga(refresh: true);
    });
  }

  /// Hitung seberapa jauh user sudah scroll (0..1) untuk bar di header.
  void _updateScrollProgress() {
    final pos = _scrollController.position;
    final max = pos.maxScrollExtent;
    _scrollProgress.value = max <= 0 ? 0 : (pos.pixels / max).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _scrollProgress.dispose();
    _headerAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<KeluargaProvider>();
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Height = inset + top pad + title row + (search block when open) + bottom pad.
          // AnimatedBuilder keeps the bar height in sync with the search field
          // animation, so content never overflows the header bounds.
          AnimatedBuilder(
            animation: _headerAnim,
            builder: (context, _) => SliverAppBar(
              expandedHeight: topInset + 88 + _headerAnim.value * 72,
              pinned: true,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: AppTheme.gradientHeaderOf(context),
                  padding: EdgeInsets.fromLTRB(20, topInset + 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Keluarga',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
                                ),
                                if (prov.total > 0)
                                  Text(
                                    '${prov.total} KK',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                _showSearch ? Icons.close_rounded : Icons.search_rounded,
                                key: ValueKey(_showSearch),
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _showSearch = !_showSearch;
                                _showSearch ? _headerAnim.forward() : _headerAnim.reverse();
                                if (!_showSearch) {
                                  _searchController.clear();
                                  prov.setSearch('');
                                }
                              });
                            },
                          ),
                          // Filter dusun
                          FilterIconButton(
                            onPressed: () => _openDusunFilter(context, prov),
                            isActive: prov.filterIdDusun != null,
                          ),
                        ],
                      ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: _showSearch
                          ? Padding(
                              padding: const EdgeInsets.only(top: 10, bottom: 14),
                              child: HeaderSearchField(
                                controller: _searchController,
                                hintText: 'Cari No. KK...',
                                onChanged: (v) => prov.setSearch(v),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            // Bar tipis di bawah header — menunjukkan posisi user
            // (seberapa jauh list sudah di-scroll).
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: ValueListenableBuilder<double>(
                valueListenable: _scrollProgress,
                builder: (context, progress, _) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      height: 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Track samar — baru tampil setelah ada scroll.
                          if (progress > 0)
                            Container(color: Colors.white.withValues(alpha: 0.25)),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(color: Colors.white.withValues(alpha: 0.95)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          ),
          // Chip filter dusun aktif (jika ada)
          if (prov.filterDusunName != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, left: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ActiveFilterChip(
                    label: 'Dusun: ${prov.filterDusunName}',
                    onClear: () => prov.setFilterDusun(null),
                  ),
                ),
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (prov.keluargaList.isEmpty) {
                    if (index == 0) {
                      if (prov.isLoading) {
                        return const SizedBox(height: 200, child: LoadingWidget());
                      }
                      if (prov.error != null) {
                        return ErrorDisplay(error: prov.error, onRetry: () => prov.loadKeluarga(refresh: true));
                      }
                      return const EmptyState(icon: Icons.family_restroom_outlined, title: 'Belum ada data keluarga');
                    }
                    return null;
                  }
                  if (index < prov.keluargaList.length) {
                    return StaggeredListAnimation(
                      index: index,
                      child: _keluargaCard(context, prov.keluargaList[index]),
                    );
                  }
                  // Footer: indikator muat-lagi / tombol muat lebih banyak /
                  // tombol tampilkan seluruh list sekaligus.
                  if (prov.isLoadingMore) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  if (prov.hasMore) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          TextButton(
                            onPressed: () => prov.loadMore(),
                            child: const Text('Muat lebih banyak...'),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => prov.loadAll(),
                              icon: const Icon(Icons.unfold_more_rounded, size: 18),
                              label: Text('Tampilkan Semua (${prov.total})'),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return null;
                },
                childCount: prov.keluargaList.isEmpty
                    ? 1
                    : prov.keluargaList.length + (prov.isLoadingMore || prov.hasMore ? 1 : 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _keluargaCard(BuildContext context, KeluargaModel k) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => KeluargaDetailScreen(noKk: k.noKk)),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.family_restroom_rounded, color: AppTheme.primary, size: 24),
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
                          k.kepalaKeluarga?.nama ?? 'Keluarga',
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
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 12, color: AppTheme.textHintOf(context)),
                      const SizedBox(width: 4),
                      Text(k.noKk, style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.textSecondaryOf(context))),
                    ],
                  ),
                  if (k.kelompokDasawisma != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.groups_outlined, size: 12, color: AppTheme.textHintOf(context)),
                        const SizedBox(width: 4),
                        Text(
                          '${k.kelompokDasawisma!.nama}${k.kelompokDasawisma!.dusun != null ? ' - ${k.kelompokDasawisma!.dusun}' : ''}',
                          style: TextStyle(fontSize: 11, color: AppTheme.textHintOf(context)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _confirmDelete(context, k),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: AppTheme.error.withValues(alpha: 0.8),
                  tooltip: 'Hapus keluarga',
                ),
                Icon(Icons.chevron_right_rounded, color: AppTheme.textHintOf(context)),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  /// Daftar dusun untuk bottom sheet filter (di-cache di State).
  Future<List<Map<String, dynamic>>>? _dusunFuture;

  /// Bottom sheet pilihan filter dusun (daftar dari `/references/dusun`).
  Future<void> _openDusunFilter(BuildContext context, KeluargaProvider prov) async {
    final cs = Theme.of(context).colorScheme;

    // Ambil daftar dusun (sekali per State, bisa di-refresh via "Coba lagi").
    _dusunFuture ??= prov.fetchDusunOptions();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            builder: (ctx, scrollController) => Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_rounded, color: cs.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Filter Dusun',
                        style: Theme.of(sheetCtx).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      if (prov.filterIdDusun != null)
                        TextButton(
                          onPressed: () {
                            prov.setFilterDusun(null);
                            Navigator.pop(sheetCtx);
                          },
                          child: const Text('Reset'),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _dusunFuture,
                    builder: (ctx, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      }
                      if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                        return EmptyState(
                          icon: Icons.location_off_rounded,
                          title: 'Daftar dusun tidak tersedia',
                          subtitle: 'Periksa koneksi lalu coba lagi',
                          actionLabel: 'Coba lagi',
                          onAction: () => setSheetState(() {
                            _dusunFuture = prov.fetchDusunOptions();
                          }),
                        );
                      }

                      final dusunList = snapshot.data!;
                      return ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          // Opsi "Semua Dusun"
                          _dusunOption(
                            ctx,
                            idDusun: null,
                            nama: 'Semua Dusun',
                            icon: Icons.all_inclusive_rounded,
                            selectedId: prov.filterIdDusun,
                            onTap: () {
                              prov.setFilterDusun(null);
                              Navigator.pop(sheetCtx);
                            },
                          ),
                          ...dusunList.map((d) => _dusunOption(
                                ctx,
                                idDusun: int.tryParse('${d['id']}'),
                                nama: '${d['nama'] ?? 'Dusun ${d['id']}'}',
                                icon: Icons.location_on_outlined,
                                selectedId: prov.filterIdDusun,
                                onTap: () {
                                  prov.setFilterDusun(
                                    int.tryParse('${d['id']}'),
                                    namaDusun: '${d['nama'] ?? ''}',
                                  );
                                  Navigator.pop(sheetCtx);
                                },
                              )),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }

  Widget _dusunOption(
    BuildContext context, {
    required int? idDusun,
    required String nama,
    required IconData icon,
    required int? selectedId,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = idDusun == selectedId;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? cs.primary : cs.onSurfaceVariant,
      ),
      title: Text(
        nama,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? cs.primary : cs.onSurface,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: cs.primary, size: 20)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  /// Konfirmasi hapus keluarga dari list. Online -> DELETE langsung;
  /// offline -> diantrekan dan dihapus saat koneksi kembali.
  void _confirmDelete(BuildContext context, KeluargaModel k) {
    final namaKepala = k.kepalaKeluarga?.nama ?? 'Keluarga';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Keluarga'),
        content: Text('Apakah Anda yakin ingin menghapus keluarga $namaKepala (No. KK ${k.noKk})? Semua anggota dan catatan terkait juga akan terpengaruh.'),
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
                  const SnackBar(content: Text('Gagal menghapus keluarga.'), behavior: SnackBarBehavior.floating),
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
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
