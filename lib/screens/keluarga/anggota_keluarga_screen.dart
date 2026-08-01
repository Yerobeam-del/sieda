import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exception.dart';
import '../../core/storage/local_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../database/local_database.dart';
import '../../models/penduduk_model.dart';
import '../../services/activity_service.dart';
import '../../services/connectivity_service.dart';
import '../../widgets/error_display.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/pending_sync_badge.dart';
import '../../widgets/penduduk_picker_sheet.dart';
import '../penduduk/penduduk_detail_screen.dart';

/// Kelola anggota keluarga (tp_pkk_anggota_keluarga) per No. KK.
/// Mendukung penambahan & penghapusan anggota secara offline — operasi
/// diantrekan ke pending_anggota_keluarga dan terkirim saat koneksi kembali.
class AnggotaKeluargaScreen extends StatefulWidget {
  final String noKk;

  const AnggotaKeluargaScreen({super.key, required this.noKk});

  @override
  State<AnggotaKeluargaScreen> createState() => _AnggotaKeluargaScreenState();
}

class _AnggotaKeluargaScreenState extends State<AnggotaKeluargaScreen> {
  List<PendudukModel> _anggota = [];
  bool _isLoading = true;
  ApiException? _error;

  @override
  void initState() {
    super.initState();
    _loadAnggota();
  }

  /// Gabungkan relasi `warga` (nested) ke level atas agar cocok dengan
  /// `PendudukModel.fromJson` yang membaca field flat (nama, jenis_kelamin,
  /// tanggal_lahir). Kompatibel dengan resource lama (nested) maupun baru.
  Map<String, dynamic> _flattenAnggota(Map<String, dynamic> e) {
    final warga = e['warga'];
    if (warga is Map<String, dynamic>) {
      return {
        ...warga,
        ...e,
        'is_kepala_keluarga': e['is_kepala_keluarga'] ?? false,
      };
    }
    return e;
  }

  Future<void> _loadAnggota() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Gabungkan anggota yang masih menunggu sinkron (disimpan offline).
    final pending = await _loadPendingAnggota();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final response = await client.get(ApiEndpoints.keluargaAnggota(widget.noKk));
      final data = response['data'] as List<dynamic>;
      if (mounted) {
        setState(() {
          _anggota = [
            ...pending,
            ...data.map(
              (e) => PendudukModel.fromJson(
                _flattenAnggota(e as Map<String, dynamic>),
              ),
            ),
          ];
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      // Offline / gagal: fallback ke cache keluarga.
      await _loadFromCache(pending);
      if (mounted) setState(() => _error = e);
    } catch (e) {
      await _loadFromCache(pending);
      if (mounted) {
        setState(() {
          _error = ApiException(message: 'Gagal memuat anggota keluarga.');
          _isLoading = false;
        });
      }
    }
  }

  /// Anggota yang masih di antrian offline (belum tersinkron ke server).
  Future<List<PendudukModel>> _loadPendingAnggota() async {
    try {
      final rows = await LocalDatabase().getUnsyncedAnggotaKeluarga();
      return rows
          .where((r) => r['no_kk'] == widget.noKk && r['action'] != 'DELETE')
          .map((r) => PendudukModel.fromJson(
                jsonDecode(r['json_data'] as String) as Map<String, dynamic>,
                isPendingSync: true,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _loadFromCache(List<PendudukModel> pending) async {
    try {
      final cached = await LocalDatabase().getCachedKeluargaList();
      for (final row in cached) {
        final jsonData = jsonDecode(row['json_data'] as String) as Map<String, dynamic>;
        if (jsonData['no_kk'] == widget.noKk) {
          final anggota = jsonData['anggota'];
          if (anggota is List) {
            if (mounted) {
              setState(() {
                _anggota = [
                  ...pending,
                  ...anggota.map(
                    (e) => PendudukModel.fromJson(
                      _flattenAnggota(e as Map<String, dynamic>),
                    ),
                  ),
                ];
                _isLoading = false;
              });
            }
            return;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  // ==================== TAMBAH ANGGOTA ====================

  Future<void> _openAddAnggota() async {
    final selected = await showPendudukPicker(
      context,
      excludedNik: _anggota.map((a) => a.nik).toSet(),
    );
    if (selected != null) await _addAnggota(selected);
  }

  Future<void> _addAnggota(PendudukModel p) async {
    final isOnline = context.read<ConnectivityService>().isOnline;
    // Simpan data lengkap agar tampilan offline & antrian sync punya nama.
    final data = {
      'no_kk': widget.noKk,
      'nik': p.nik,
      'nama': p.nama,
      'jenis_kelamin': p.jenisKelamin,
      'tanggal_lahir': p.tanggalLahir,
    };

    if (isOnline) {
      try {
        final token = await LocalStorage.getToken();
        final client = ApiClient(token: token!);
        // Backend storeBulk mengharapkan array `anggota`, bukan objek tunggal.
        await client.post(
          ApiEndpoints.keluargaAnggota(widget.noKk),
          data: {
            'anggota': [
              {'nik': p.nik}
            ]
          },
        );
        if (!mounted) return;
        await ActivityService().logSave(
          tipe: 'Anggota',
          nama: p.nama,
          identifier: p.nik,
          isOnline: true,
        );
        _showSnackbar('${p.nama} ditambahkan ke keluarga.');
        await _loadAnggota();
        return;
      } on ApiException catch (e) {
        if (!mounted) return;
        _showSnackbar(e.friendlyMessage);
        return;
      } catch (e) {
        // Jatuh ke mode offline di bawah.
      }
    }

    // Offline: antrekan CREATE agar terkirim saat koneksi kembali.
    // Guard: cegah duplikat lokal jika pengguna memilih orang yang sama 2x.
    if (_anggota.any((x) => x.nik == p.nik)) {
      if (!mounted) return;
      _showSnackbar('${p.nama} sudah menjadi anggota keluarga.');
      return;
    }
    await LocalDatabase().savePendingAnggotaKeluarga(data);
    await ActivityService().logSave(
      tipe: 'Anggota',
      nama: p.nama,
      identifier: p.nik,
      isOnline: false,
    );
    if (!mounted) return;
    setState(() => _anggota.add(p.copyWith(isPendingSync: true)));
    _showSnackbar('${p.nama} disimpan offline. Akan dikirim saat online.');
  }

  // ==================== HAPUS ANGGOTA ====================

  Future<void> _removeAnggota(PendudukModel a) async {
    // Kepala Keluarga tidak dapat dikeluarkan (server menolak) — cegah sejak
    // awal agar user tidak melihat error di tengah proses.
    if (a.isKepalaKeluarga) {
      _showSnackbar('Kepala Keluarga tidak dapat dikeluarkan dari keluarga.');
      return;
    }

    // Ambil status koneksi SEBELUM await agar tidak ada async gap pada context.
    final isOnline = context.read<ConnectivityService>().isOnline;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Anggota?'),
        content: Text('Keluarkan ${a.nama} dari keluarga ini?'),
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
    if (confirmed != true) return;

    if (isOnline) {
      try {
        final token = await LocalStorage.getToken();
        final client = ApiClient(token: token!);
        await client.delete(ApiEndpoints.keluargaAnggotaRemove(widget.noKk, a.nik));
        if (!mounted) return;
        await ActivityService().logDelete(
          tipe: 'Anggota',
          nama: a.nama,
          identifier: a.nik,
        );
        setState(() => _anggota.removeWhere((x) => x.nik == a.nik));
        _showSnackbar('${a.nama} dikeluarkan dari keluarga.');
        return;
      } on ApiException catch (e) {
        if (!mounted) return;
        _showSnackbar(e.friendlyMessage);
        return;
      } catch (e) {
        // Jatuh ke mode offline di bawah.
      }
    }

    // Offline: antrekan DELETE agar terkirim saat koneksi kembali.
    await LocalDatabase().queuePendingDeleteAnggotaKeluarga(widget.noKk, a.nik);
    await ActivityService().logDelete(
      tipe: 'Anggota',
      nama: a.nama,
      identifier: a.nik,
    );
    if (!mounted) return;
    setState(() => _anggota.removeWhere((x) => x.nik == a.nik));
    _showSnackbar('${a.nama} akan dikeluarkan saat online.');
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityService>().isOnline;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggota Keluarga'),
        actions: [
          if (!isOnline)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded, size: 14, color: AppTheme.warning),
                  SizedBox(width: 4),
                  Text('Offline', style: TextStyle(fontSize: 11, color: AppTheme.warning)),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAnggota,
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddAnggota,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
        label: const Text('Tambah Anggota'),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null && _anggota.isEmpty
              ? ErrorDisplay(error: _error, onRetry: _loadAnggota)
              : RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: _loadAnggota,
                  child: _anggota.isEmpty
                      ? const SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: 500,
                            child: EmptyState(
                              icon: Icons.person_add_alt_1_outlined,
                              title: 'Belum ada anggota',
                              subtitle: 'Tekan + untuk menambahkan anggota keluarga',
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _anggota.length,
                          itemBuilder: (context, index) {
                            final a = _anggota[index];
                            return _anggotaCard(context, a);
                          },
                        ),
                ),
    );
  }

  Widget _anggotaCard(BuildContext context, PendudukModel a) {
    final isMale = a.jenisKelamin?.toUpperCase().trim() == 'L' || a.jenisKelamin?.toUpperCase().trim() == 'LAKI-LAKI';
    final genderColor = isMale ? AppTheme.male : AppTheme.female;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PendudukDetailScreen(nik: a.nik)),
        ),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: genderColor.withValues(alpha: 0.15),
          child: Text(Helpers.getInitials(a.nama), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: genderColor)),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(a.nama, style: Theme.of(context).textTheme.titleMedium),
            ),
            if (a.isKepalaKeluarga) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 13, color: AppTheme.primary),
                    const SizedBox(width: 3),
                    Text(
                      'Kepala Keluarga',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
            ],
            if (a.isPendingSync) ...[
              const SizedBox(width: 8),
              const PendingSyncBadge(),
            ],
          ],
        ),
        subtitle: Text(
          '${a.nik}\n${a.genderLabel}${a.usiaLabel != '-' ? ' | ${a.usiaLabel}' : ''}',
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryOf(context)),
          maxLines: 2,
        ),
        // Kepala Keluarga tidak dapat dikeluarkan (ditolak server) — tampilkan
        // indikasi yang jelas, bukan tombol hapus yang gagal diam-diam.
        trailing: a.isKepalaKeluarga
            ? Tooltip(
                message: 'Kepala Keluarga tidak dapat dikeluarkan dari keluarga',
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.lock_outline_rounded, color: Colors.grey),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.person_remove_outlined, color: AppTheme.error),
                tooltip: 'Keluarkan dari keluarga',
                onPressed: () => _removeAnggota(a),
              ),
      ),
    );
  }
}
