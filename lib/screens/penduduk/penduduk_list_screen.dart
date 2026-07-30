import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../providers/penduduk_provider.dart';
import '../../models/penduduk_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_display.dart';
import '../../widgets/animations/page_transitions.dart';
import 'penduduk_detail_screen.dart';
import 'forms/penduduk_form_screen.dart';

class PendudukListScreen extends StatefulWidget {
  const PendudukListScreen({super.key});

  @override
  State<PendudukListScreen> createState() => _PendudukListScreenState();
}

class _PendudukListScreenState extends State<PendudukListScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PendudukProvider>().loadPenduduk(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<PendudukProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            SlideTransitionRoute(page: const PendudukFormScreen()),
          );
          if (result == true) prov.loadPenduduk(refresh: true);
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded, size: 20),
        label: const Text('Tambah'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: _showSearch ? 150 : 120,
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
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                              if (prov.total > 0)
                                Text(
                                  '${prov.total} jiwa',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.white.withOpacity(0.85),
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
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  onChanged: (v) => prov.setSearch(v),
                                  decoration: InputDecoration(
                                    hintText: 'Cari NIK atau nama...',
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                    border: InputBorder.none,
                                    prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.7)),
                                    suffixIcon: _searchController.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(Icons.clear_rounded, color: Colors.white.withOpacity(0.7), size: 18),
                                            onPressed: () {
                                              _searchController.clear();
                                              prov.setSearch('');
                                            },
                                          )
                                        : null,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (prov.isLoading && prov.pendudukList.isEmpty)
                  const SizedBox(height: 200, child: LoadingWidget())
                else if (prov.error != null)
                  ErrorDisplay(
                    error: prov.error,
                    onRetry: () => prov.loadPenduduk(refresh: true),
                  )
                else if (prov.pendudukList.isEmpty)
                  const EmptyState(
                    icon: Icons.people_outline_rounded,
                    title: 'Belum ada data penduduk',
                  )
                else
                  ...prov.pendudukList.asMap().entries.map((entry) => StaggeredListAnimation(
                    index: entry.key,
                    child: _pendudukCard(context, entry.value),
                  )),

                if (prov.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),

                if (prov.hasMore && !prov.isLoadingMore)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: TextButton(
                        onPressed: () => prov.loadMore(),
                        child: const Text('Muat lebih banyak...'),
                      ),
                    ),
                  ),
              ]),
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
              backgroundColor: genderColor.withOpacity(0.15),
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
                  Text(p.nama, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 12, color: AppTheme.textHint),
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
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
          ],
        ),
      ),
    ),
    );
  }

  Widget _infoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}
