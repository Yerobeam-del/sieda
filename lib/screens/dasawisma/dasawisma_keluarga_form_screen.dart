import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exception.dart';
import '../../core/storage/local_storage.dart';
import '../../database/local_database.dart';
import '../../models/dasawisma_model.dart';

class DasawismaKeluargaFormScreen extends StatefulWidget {
  final String? initialNoKK;
  final DasawismaKeluargaData? data;

  const DasawismaKeluargaFormScreen({super.key, this.initialNoKK, this.data});

  @override
  State<DasawismaKeluargaFormScreen> createState() => _DasawismaKeluargaFormScreenState();
}

class _DasawismaKeluargaFormScreenState extends State<DasawismaKeluargaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _noKKController;
  late final TextEditingController _jumlahBalitaController;
  late final TextEditingController _jumlahIbuHamilController;
  late final TextEditingController _jumlahIbuMenyusuiController;
  late final TextEditingController _jumlahLansiaController;
  late final TextEditingController _jumlahStuntingController;
  late final TextEditingController _jumlahDisabilitasController;
  late final TextEditingController _jumlahGiziKurangController;
  late final TextEditingController _jumlahGiziBurukController;

  String? _statusJamban;
  String? _statusSampah;
  String? _statusSPAL;
  String? _kriteriaRumah;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _noKKController = TextEditingController(text: d?.noKK ?? widget.initialNoKK ?? '');
    _jumlahBalitaController = TextEditingController(text: d?.jumlahBalita?.toString() ?? '');
    _jumlahIbuHamilController = TextEditingController(text: d?.jumlahIbuHamil?.toString() ?? '');
    _jumlahIbuMenyusuiController = TextEditingController(text: d?.jumlahIbuMenyusui?.toString() ?? '');
    _jumlahLansiaController = TextEditingController(text: d?.jumlahLansia?.toString() ?? '');
    _jumlahStuntingController = TextEditingController(text: d?.jumlahStunting?.toString() ?? '');
    _jumlahDisabilitasController = TextEditingController(text: d?.jumlahDisabilitas?.toString() ?? '');
    _jumlahGiziKurangController = TextEditingController(text: d?.jumlahGiziKurang?.toString() ?? '');
    _jumlahGiziBurukController = TextEditingController(text: d?.jumlahGiziBuruk?.toString() ?? '');
    _statusJamban = d?.statusJamban;
    _statusSampah = d?.statusTempatPembuanganSampah;
    _statusSPAL = d?.statusSaluranPembuangan;
    _kriteriaRumah = d?.kriteriaRumah;
  }

  @override
  void dispose() {
    _noKKController.dispose();
    _jumlahBalitaController.dispose();
    _jumlahIbuHamilController.dispose();
    _jumlahIbuMenyusuiController.dispose();
    _jumlahLansiaController.dispose();
    _jumlahStuntingController.dispose();
    _jumlahDisabilitasController.dispose();
    _jumlahGiziKurangController.dispose();
    _jumlahGiziBurukController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'no_kk': _noKKController.text.trim(),
      'config_year': DateTime.now().year,
      'jumlah_balita': _parseInt(_jumlahBalitaController.text),
      'jumlah_ibu_hamil': _parseInt(_jumlahIbuHamilController.text),
      'jumlah_ibu_menyusui': _parseInt(_jumlahIbuMenyusuiController.text),
      'jumlah_lansia': _parseInt(_jumlahLansiaController.text),
      'jumlah_stunting': _parseInt(_jumlahStuntingController.text),
      'jumlah_disabilitas': _parseInt(_jumlahDisabilitasController.text),
      'jumlah_gizi_kurang': _parseInt(_jumlahGiziKurangController.text),
      'jumlah_gizi_buruk': _parseInt(_jumlahGiziBurukController.text),
      'status_jamban': _statusJamban,
      'status_tempat_pembuangan_sampah': _statusSampah,
      'status_saluran_pembuangan': _statusSPAL,
      'kriteria_rumah': _kriteriaRumah,
    };

    data.removeWhere((key, value) => value == null || (value is String && value.isEmpty));

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      await client.post(ApiEndpoints.dasawismaKeluarga, data: data);

      if (!mounted) return;
      _showSnackbar('Data kesehatan berhasil disimpan');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showSnackbar(e.friendlyMessage);
      _offerOfflineSave(data);
    } catch (e) {
      if (!mounted) return;
      _showSnackbar('Gagal terhubung ke server.');
      _offerOfflineSave(data);
    }

    setState(() => _isLoading = false);
  }

  int? _parseInt(String text) {
    final v = int.tryParse(text.trim());
    return v != null && v >= 0 ? v : null;
  }

  void _offerOfflineSave(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Simpan Offline?'),
        content: const Text('Data akan disimpan dan dikirim saat online.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              LocalDatabase().savePendingDasawisma(data, 'kesehatan');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Data Kesehatan Keluarga')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionHeader('Data Keluarga', Icons.family_restroom_rounded),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noKKController,
                decoration: const InputDecoration(labelText: 'No. KK *', prefixIcon: Icon(Icons.badge_outlined)),
                readOnly: widget.data != null,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'No. KK wajib diisi' : null,
              ),
              const SizedBox(height: 20),

              _sectionHeader('Data Balita & Ibu', Icons.child_care_rounded),
              const SizedBox(height: 12),
              _numberField(_jumlahBalitaController, 'Jumlah Balita'),
              _numberField(_jumlahIbuHamilController, 'Jumlah Ibu Hamil'),
              _numberField(_jumlahIbuMenyusuiController, 'Jumlah Ibu Menyusui'),
              const SizedBox(height: 20),

              _sectionHeader('Data Gizi & Kesehatan', Icons.health_and_safety_rounded),
              const SizedBox(height: 12),
              _numberField(_jumlahStuntingController, 'Jumlah Stunting'),
              _numberField(_jumlahGiziKurangController, 'Jumlah Gizi Kurang'),
              _numberField(_jumlahGiziBurukController, 'Jumlah Gizi Buruk'),
              _numberField(_jumlahDisabilitasController, 'Jumlah Disabilitas'),
              _numberField(_jumlahLansiaController, 'Jumlah Lansia'),
              const SizedBox(height: 20),

              _sectionHeader('Sanitasi & Rumah', Icons.home_rounded),
              const SizedBox(height: 12),
              _statusDropdown('Status Jamban', _statusJamban, (v) => _statusJamban = v, [
                'Sehat', 'Tidak Sehat', 'Tidak Ada', 'Lainnya',
              ]),
              const SizedBox(height: 12),
              _statusDropdown('Tempat Pembuangan Sampah', _statusSampah, (v) => _statusSampah = v, [
                'Sehat', 'Tidak Sehat', 'Tidak Ada', 'Lainnya',
              ]),
              const SizedBox(height: 12),
              _statusDropdown('Saluran Pembuangan (SPAL)', _statusSPAL, (v) => _statusSPAL = v, [
                'Sehat', 'Tidak Sehat', 'Tidak Ada', 'Lainnya',
              ]),
              const SizedBox(height: 12),
              _statusDropdown('Kriteria Rumah', _kriteriaRumah, (v) => _kriteriaRumah = v, [
                'Sehat', 'Kurang Sehat', 'Tidak Sehat', 'Lainnya',
              ]),
              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('SIMPAN DATA KESEHATAN'),
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

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: AppTheme.primary),
        ),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.numbers_rounded)),
        keyboardType: TextInputType.number,
      ),
    );
  }

  Widget _statusDropdown(String label, String? value, ValueChanged<String?> onChanged, List<String> options) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.checklist_rounded)),
      items: [
        const DropdownMenuItem(value: null, child: Text('- Pilih -', style: TextStyle(color: AppTheme.textHint))),
        ...options.map((o) => DropdownMenuItem(value: o, child: Text(o))),
      ],
      onChanged: onChanged,
    );
  }
}
