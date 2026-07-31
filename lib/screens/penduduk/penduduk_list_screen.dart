import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../providers/penduduk_provider.dart';
import '../../models/penduduk_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_display.dart';
import '../../widgets/animations/page_transitions.dart';
import '../../widgets/pending_sync_badge.dart';
import '../../widgets/header_search_field.dart';
import 'penduduk_detail_screen.dart';

class PendudukListScreen extends StatefulWidget {
  const PendudukListScreen({super.key});

  @override
  State<PendudukListScreen> createState() => _PendudukListScreenState();
}

class _PendudukListScreenState extends State<PendudukListScreen>
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
      context.read<PendudukProvider>().loadPenduduk(refresh: true);
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
    final prov = context.watch<PendudukProvider>();
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
                      // Title row with search toggle
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Penduduk',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                        color: Colors.white,
                                      ),
                                ),
                                if (prov.total > 0)
                                  Text(
                                    '${prov.total} jiwa',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Colors.white.withValues(alpha: 0.85),
                                        ),
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
                    // Search field - always visible when showSearch is true
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: _showSearch
                          ? Padding(
                              padding: const EdgeInsets.only(top: 10, bottom: 14),
                              child: HeaderSearchField(
                                controller: _searchController,
                                hintText: 'Cari NIK atau nama...',
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
                  if (prov.pendudukList.isEmpty) {
                    if (index == 0) {
                      if (prov.isLoading) {
                        return const SizedBox(height: 200, child: LoadingWidget());
                      }
                      if (prov.error != null) {
                        return ErrorDisplay(
                          error: prov.error,
                          onRetry: () => prov.loadPenduduk(refresh: true),
                        );
                      }
                      return const EmptyState(
                        icon: Icons.people_outline_rounded,
                        title: 'Belum ada data penduduk',
                      );
                    }
                    return null;
                  }
                  if (index < prov.pendudukList.length) {
                    return StaggeredListAnimation(
                      index: index,
                      child: _pendudukCard(context, prov.pendudukList[index]),
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
                childCount: prov.pendudukList.isEmpty
                    ? 1
                    : prov.pendudukList.length + (prov.isLoadingMore || prov.hasMore ? 1 : 0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendudukCard(BuildContext context, PendudukModel p) {
    final isMale = p.jenisKelamin?.toUpperCase().trim() == 'L' ||
        p.jenisKelamin?.toUpperCase().trim() == 'LAKI-LAKI';
    final genderColor = isMale ? AppTheme.male : AppTheme.female;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PendudukDetailScreen(nik: p.nik)),
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
            CircleAvatar(
              radius: 24,
              backgroundColor: genderColor.withValues(alpha: 0.15),
              child: Text(
                Helpers.getInitials(p.nama),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: genderColor,
                  fontSize: 14,
                ),
              ),
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
                          p.nama,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (p.isPendingSync) ...[
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
                      Text(
                        p.nik,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _infoChip(p.genderLabel, genderColor),
                      const SizedBox(width: 6),
                      if (p.usiaLabel != '-') _infoChip(p.usiaLabel, AppTheme.info),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _confirmDelete(context, p),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: AppTheme.error.withValues(alpha: 0.8),
                  tooltip: 'Hapus penduduk',
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

  /// Konfirmasi hapus penduduk dari list. Online -> DELETE langsung;
  /// offline -> diantrekan dan dihapus saat koneksi kembali.
  void _confirmDelete(BuildContext context, PendudukModel p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Penduduk'),
        content: Text('Apakah Anda yakin ingin menghapus ${p.nama} (NIK ${p.nik})? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await context.read<PendudukProvider>().deletePenduduk(p);
              if (!context.mounted) return;

              if (!result.handled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gagal menghapus penduduk.'), behavior: SnackBarBehavior.floating),
                );
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.queuedOffline
                      ? 'Penduduk akan dihapus saat online.'
                      : 'Penduduk berhasil dihapus.'),
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

  Widget _infoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
