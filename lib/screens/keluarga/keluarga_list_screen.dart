import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/keluarga_provider.dart';
import '../../models/keluarga_model.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_display.dart';
import '../../widgets/animations/page_transitions.dart';
import 'keluarga_detail_screen.dart';
import 'forms/keluarga_form_screen.dart';

class KeluargaListScreen extends StatefulWidget {
  const KeluargaListScreen({super.key});

  @override
  State<KeluargaListScreen> createState() => _KeluargaListScreenState();
}

class _KeluargaListScreenState extends State<KeluargaListScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KeluargaProvider>().loadKeluarga(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<KeluargaProvider>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            SlideTransitionRoute(page: const KeluargaFormScreen()),
          );
          if (result == true) prov.loadKeluarga(refresh: true);
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Keluarga', style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white)),
                              if (prov.total > 0)
                                Text('${prov.total} KK', style: TextStyle(color: Colors.white.withOpacity(0.85))),
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
                                    hintText: 'Cari No. KK...',
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
                if (prov.isLoading && prov.keluargaList.isEmpty)
                  const SizedBox(height: 200, child: LoadingWidget())
                else if (prov.error != null)
                  ErrorDisplay(error: prov.error, onRetry: () => prov.loadKeluarga(refresh: true))
                else if (prov.keluargaList.isEmpty)
                  const EmptyState(icon: Icons.family_restroom_outlined, title: 'Belum ada data keluarga')
                else
                  ...prov.keluargaList.asMap().entries.map((entry) => StaggeredListAnimation(
                    index: entry.key,
                    child: _keluargaCard(context, entry.value),
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
                      child: TextButton(onPressed: () => prov.loadMore(), child: const Text('Muat lebih banyak...')),
                    ),
                  ),
              ]),
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.cardDecoration,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.family_restroom_rounded, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    k.kepalaKeluarga?.nama ?? 'Keluarga',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 12, color: AppTheme.textHint),
                      const SizedBox(width: 4),
                      Text(k.noKk, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                  if (k.kelompokDasawisma != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.groups_outlined, size: 12, color: AppTheme.textHint),
                        const SizedBox(width: 4),
                        Text(
                          '${k.kelompokDasawisma!.nama}${k.kelompokDasawisma!.dusun != null ? ' - ${k.kelompokDasawisma!.dusun}' : ''}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}
