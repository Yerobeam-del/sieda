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
