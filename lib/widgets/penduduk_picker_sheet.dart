import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/pagination_helper.dart';
import '../core/storage/local_storage.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../database/local_database.dart';
import '../models/penduduk_model.dart';
import '../services/connectivity_service.dart';

/// Buka bottom sheet pencari penduduk. Mengembalikan penduduk yang dipilih,
/// atau `null` bila dibatalkan.
///
/// Dipakai untuk memilih Anggota Keluarga, Kepala Keluarga, dll. Bekerja
/// online (API) maupun offline (cache lokal).
Future<PendudukModel?> showPendudukPicker(
  BuildContext context, {
  Set<String> excludedNik = const {},
}) {
  return showModalBottomSheet<PendudukModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PendudukPickerSheet(excludedNik: excludedNik),
  );
}

/// Bottom sheet pencari penduduk untuk dipilih (anggota keluarga, kepala
/// keluarga, dll).
class PendudukPickerSheet extends StatefulWidget {
  /// NIK yang tidak boleh dipilih (mis. anggota yang sudah terdaftar).
  final Set<String> excludedNik;

  const PendudukPickerSheet({super.key, this.excludedNik = const {}});

  @override
  State<PendudukPickerSheet> createState() => _PendudukPickerSheetState();
}

class _PendudukPickerSheetState extends State<PendudukPickerSheet> {
  final _searchController = TextEditingController();

  /// Debounce pencarian: tunggu [DebounceDelay] setelah jeda ketik sebelum
  /// mengirim request API — mencegah request per ketukan tombol.
  Timer? _debounce;
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  /// Penanda urutan pencarian. Respons yang sudah basi (dari pencarian lama
  /// yang selesai belakangan) diabaikan agar tidak menimpa hasil terbaru.
  int _searchSeq = 0;

  List<PendudukModel> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Handler onChanged: jadwalkan pencarian setelah jeda 300ms tanpa ketikan.
  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, _search);
  }

  Future<void> _search() async {
    _debounce?.cancel();
    final seq = ++_searchSeq;
    setState(() => _isLoading = true);
    final query = _searchController.text.trim();
    final isOnline = context.read<ConnectivityService>().isOnline;
    final results = <PendudukModel>[];

    if (isOnline) {
      try {
        final token = await LocalStorage.getToken();
        final client = ApiClient(token: token!);
        final response = await fetchAllPages(
          client,
          ApiEndpoints.penduduk,
          queryParameters: {
            if (query.isNotEmpty) 'search': query,
          },
        );
        final data = response['data'] as List<dynamic>;
        results.addAll(data.map((e) => PendudukModel.fromJson(e as Map<String, dynamic>)));
      } catch (_) {
        // Jatuh ke pencarian cache di bawah.
        results.addAll(await _searchCache(query));
      }
    } else {
      results.addAll(await _searchCache(query));
    }

    // Filter penduduk yang tidak boleh dipilih.
    results.removeWhere((p) => widget.excludedNik.contains(p.nik));

    if (!mounted || seq != _searchSeq) return; // Respons basi diabaikan.
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  Future<List<PendudukModel>> _searchCache(String query) async {
    try {
      final cached = await LocalDatabase().getCachedPendudukList();
      final all = cached.map((row) {
        try {
          return PendudukModel.fromJson(jsonDecode(row['json_data'] as String) as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      }).whereType<PendudukModel>().toList();

      if (query.isEmpty) return all;
      final q = query.toLowerCase();
      return all
          .where((p) => p.nama.toLowerCase().contains(q) || p.nik.contains(q))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        height: MediaQuery.sizeOf(context).height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textHintOf(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Pilih Penduduk', style: Theme.of(context).textTheme.titleLarge),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _search(),
                  onChanged: _onQueryChanged,
                  // Warna eksplisit & sadar-tema: field tema terang (fill
                  // hampir putih tanpa border tegas) nyaris tak terlihat di
                  // atas sheet putih — ini memastikan search bar selalu
                  // kelihatan jelas di tema terang maupun gelap.
                  style: TextStyle(color: cs.onSurface, fontSize: 15),
                  cursorColor: cs.primary,
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau NIK...',
                    hintStyle: TextStyle(color: cs.onSurfaceVariant),
                    prefixIcon: Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _debounce?.cancel();
                              _searchController.clear();
                              _search();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: cs.surfaceContainerHighest,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.outlineVariant),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: cs.primary, width: 1.5),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Indikator loading tipis di bawah kolom pencarian — tampil
              // saat hasil lama masih terlihat dan pencarian berjalan. Saat
              // belum ada hasil sama sekali, spinner tengah yang bertugas.
              if (_isLoading && _results.isNotEmpty) const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: _isLoading && _results.isEmpty
                    ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                    : _results.isEmpty
                        ? const Center(
                            child: Text('Tidak ada penduduk ditemukan', style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.builder(
                            itemCount: _results.length,
                            itemBuilder: (context, index) {
                              final p = _results[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                                  child: Text(
                                    Helpers.getInitials(p.nama),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primary),
                                  ),
                                ),
                                title: Text(p.nama, style: const TextStyle(fontSize: 14)),
                                subtitle: Text(p.nik, style: const TextStyle(fontSize: 11)),
                                trailing: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primary),
                                onTap: () => Navigator.pop(context, p),
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
}
