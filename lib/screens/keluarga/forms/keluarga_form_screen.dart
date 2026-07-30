import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/storage/local_storage.dart';
import '../../../database/local_database.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/activity_service.dart';
import '../../../models/keluarga_model.dart';
import '../../../models/reference_model.dart';
import '../../../providers/reference_provider.dart';
import '../../../widgets/location_picker_widget.dart';

class KeluargaFormScreen extends StatefulWidget {
  final KeluargaModel? keluarga;
  final String? initialNoKk;

  const KeluargaFormScreen({super.key, this.keluarga, this.initialNoKk});

  @override
  State<KeluargaFormScreen> createState() => _KeluargaFormScreenState();
}

class _KeluargaFormScreenState extends State<KeluargaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _noKkController;
  late final TextEditingController _kepalaKeluargaController;

  int? _idKelompokDasawisma;
  List<KelompokDasawismaItem> _kelompokList = [];
  bool _isLoadingKelompok = false;

  bool _isLoading = false;
  bool _isSavingOffline = false;

  bool get _isEditing => widget.keluarga != null;

  @override
  void initState() {
    super.initState();
    final k = widget.keluarga;
    _noKkController = TextEditingController(text: k?.noKk ?? widget.initialNoKk ?? '');
    _kepalaKeluargaController = TextEditingController(text: k?.kepalaKeluarga?.nik ?? '');

    if (k?.idKelompokDasawisma != null) {
      _idKelompokDasawisma = int.tryParse(k!.idKelompokDasawisma!);
    }

    _loadKelompok();
  }

  Future<void> _loadKelompok() async {
    setState(() => _isLoadingKelompok = true);
    final refProv = context.read<ReferenceProvider>();
    final list = await refProv.loadKelompokDasawisma();
    if (mounted) {
      setState(() {
        _kelompokList = list;
        _isLoadingKelompok = false;
      });
    }
  }

  @override
  void dispose() {
    _noKkController.dispose();
    _kepalaKeluargaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idKelompokDasawisma == null) {
      _showSnackbar('Pilih kelompok dasawisma');
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'no_kk': _noKkController.text.trim(),
      'id_kepala_keluarga': _kepalaKeluargaController.text.trim(),
      'id_kelompok_dasawisma': _idKelompokDasawisma,
      'config_year': DateTime.now().year,
    };

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);

      if (_isEditing) {
        await client.put(ApiEndpoints.keluargaDetail(widget.keluarga!.noKk), data: data);
      } else {
        await client.post(ApiEndpoints.keluarga, data: data);
      }

      if (!mounted) return;
      _showSnackbar(_isEditing ? 'Keluarga berhasil diperbarui' : 'Keluarga berhasil ditambahkan');
      ActivityService().logSave(
        tipe: 'Keluarga',
        nama: _noKkController.text.trim(),
        identifier: _noKkController.text.trim(),
        isEdit: _isEditing,
        isOnline: true,
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnackbar(e.friendlyMessage);
      if (e.statusCode != 422) _offerOfflineSave(data);
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Gagal terhubung ke server.');
      _offerOfflineSave(data);
    }

    setState(() => _isLoading = false);
  }

  void _offerOfflineSave(Map<String, dynamic> data) async {
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Simpan Offline?'),
        content: const Text('Data keluarga akan disimpan di perangkat dan dikirim saat online.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Simpan Offline', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (save == true) {
      setState(() => _isSavingOffline = true);
      await LocalDatabase().savePendingKeluarga(data);
      ActivityService().logSave(
        tipe: 'Keluarga',
        nama: data['no_kk'] ?? '',
        identifier: data['id_kepala_keluarga'],
        isEdit: _isEditing,
        isOnline: false,
      );
      setState(() => _isSavingOffline = false);
      if (!mounted) return;
      _showSnackbar('Data disimpan offline.');
      Navigator.of(context).pop(true);
    }
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityService>().isOnline;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Keluarga' : 'Tambah Keluarga'),
        actions: [
          if (!isOnline)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.2),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppTheme.info, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pastikan NIK Kepala Keluarga sudah terdaftar di data Penduduk.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.info),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // No. KK
              TextFormField(
                controller: _noKkController,
                decoration: const InputDecoration(
                  labelText: 'No. KK *',
                  hintText: '16 digit nomor KK',
                  prefixIcon: Icon(Icons.family_restroom_outlined),
                ),
                maxLength: 16,
                keyboardType: TextInputType.number,
                readOnly: _isEditing,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'No. KK wajib diisi';
                  if (v.trim().length < 16) return 'No. KK minimal 16 digit';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // NIK Kepala Keluarga
              TextFormField(
                controller: _kepalaKeluargaController,
                decoration: const InputDecoration(
                  labelText: 'NIK Kepala Keluarga *',
                  hintText: 'NIK yang sudah terdaftar',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'NIK Kepala Keluarga wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Kelompok Dasawisma
              if (_isLoadingKelompok)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                DropdownButtonFormField<int>(
                  value: _idKelompokDasawisma,
                  decoration: const InputDecoration(
                    labelText: 'Kelompok Dasawisma *',
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                  items: [
                    const DropdownMenuItem<int>(
                      value: null,
                      child: Text('- Pilih Kelompok -', style: TextStyle(color: AppTheme.textHint)),
                    ),
                    ..._kelompokList.map((item) => DropdownMenuItem<int>(
                          value: item.id,
                          child: Text(item.label),
                        )),
                  ],
                  onChanged: (v) => setState(() => _idKelompokDasawisma = v),
                ),
              const SizedBox(height: 16),

              // Location Picker — GPS + Mini Map
              const LocationPickerWidget(),
              const SizedBox(height: 4),
              Text(
                'Lokasi akan terisi otomatis saat deteksi GPS di form penduduk.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textHint, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),

              // Submit
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isSavingOffline) ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isEditing ? Icons.save_rounded : Icons.add_circle_outline_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(_isEditing ? 'SIMPAN PERUBAHAN' : 'TAMBAH KELUARGA'),
                          ],
                        ),
                ),
              ),
              if (_isSavingOffline) ...[
                const SizedBox(height: 8),
                const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 8),
                      Text('Menyimpan offline...'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
