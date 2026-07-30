import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exception.dart';
import '../../core/storage/local_storage.dart';
import '../../database/local_database.dart';
import '../../services/connectivity_service.dart';
import '../../models/dasawisma_model.dart';
import '../../providers/reference_provider.dart';

class DasawismaKelompokFormScreen extends StatefulWidget {
  final KelompokDasawismaModel? kelompok;

  const DasawismaKelompokFormScreen({super.key, this.kelompok});

  @override
  State<DasawismaKelompokFormScreen> createState() => _DasawismaKelompokFormScreenState();
}

class _DasawismaKelompokFormScreenState extends State<DasawismaKelompokFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaController;
  late final TextEditingController _kaderController;

  int? _idDusun;
  bool _isLoading = false;

  bool get _isEditing => widget.kelompok != null;

  @override
  void initState() {
    super.initState();
    final k = widget.kelompok;
    _namaController = TextEditingController(text: k?.nama ?? '');
    _kaderController = TextEditingController(text: k?.namaKader ?? '');
    _idDusun = k?.idDusun;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReferenceProvider>().loadReferences();
    });
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kaderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idDusun == null) {
      _showSnackbar('Pilih dusun');
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'nama': _namaController.text.trim(),
      'id_dusun': _idDusun,
      'kader': _kaderController.text.trim().isNotEmpty ? _kaderController.text.trim() : null,
      'config_year': DateTime.now().year,
    };

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);

      if (_isEditing) {
        await client.put(ApiEndpoints.dasawismaKelompokDetail(widget.kelompok!.id), data: data);
      } else {
        await client.post(ApiEndpoints.dasawismaKelompok, data: data);
      }

      if (!mounted) return;
      _showSnackbar(_isEditing ? 'Kelompok berhasil diperbarui' : 'Kelompok berhasil ditambahkan');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnackbar(e.friendlyMessage);
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Gagal terhubung ke server.');
      _offerOfflineSave(data);
    }

    setState(() => _isLoading = false);
  }

  void _offerOfflineSave(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Simpan Offline?'),
        content: const Text('Data akan disimpan di perangkat dan dikirim saat online.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              LocalDatabase().savePendingDasawisma(data, 'kelompok');
              if (!mounted) return;
              _showSnackbar('Data disimpan offline.');
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Simpan Offline', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
    final refProv = context.watch<ReferenceProvider>();
    final refs = refProv.data;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Kelompok' : 'Tambah Kelompok'),
        actions: [
          if (!isOnline)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.warning.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
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
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Kelompok *',
                  hintText: 'Nama kelompok dasawisma',
                  prefixIcon: Icon(Icons.groups_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: _idDusun,
                decoration: const InputDecoration(
                  labelText: 'Dusun *',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('- Pilih Dusun -', style: TextStyle(color: AppTheme.textHint))),
                  ...?refs?.dusun.map((d) => DropdownMenuItem(value: d.id, child: Text(d.nama))),
                ],
                onChanged: (v) => setState(() => _idDusun = v),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _kaderController,
                decoration: const InputDecoration(
                  labelText: 'Kader / PIC',
                  hintText: 'Nama kader (opsional)',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isEditing ? Icons.save_rounded : Icons.add_circle_outline_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(_isEditing ? 'SIMPAN PERUBAHAN' : 'TAMBAH KELOMPOK'),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
