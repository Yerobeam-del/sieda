import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exception.dart';
import '../../core/storage/local_storage.dart';
import '../../database/local_database.dart';
import '../../models/dasawisma_model.dart';
import '../../models/reference_model.dart';
import '../../providers/reference_provider.dart';

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
  late final TextEditingController _jumlahKKController;
  late final TextEditingController _jumlahBalitaLakiController;
  late final TextEditingController _jumlahBalitaPerempuanController;
  late final TextEditingController _jumlahPusController;
  late final TextEditingController _jumlahWusController;
  late final TextEditingController _jumlahButaController;
  late final TextEditingController _jumlahIbuHamilController;
  late final TextEditingController _jumlahIbuMenyusuiController;
  late final TextEditingController _jumlahLansiaController;
  late final TextEditingController _jumlahGiziKurangController;
  late final TextEditingController _jumlahGiziBurukController;
  late final TextEditingController _jumlahStuntingController;
  late final TextEditingController _jumlahDisabilitasController;
  late final TextEditingController _jumlahJambanController;

  String? _makananPokok; // Beras / Non Beras
  int? _idJenisMakananPokok;
  String? _statusJamban; // Ya / Tidak
  int? _idSumberAir;
  String? _statusSampah; // Ya / Tidak
  String? _statusSPAL; // Ya / Tidak
  String? _statusP4k; // Ya / Tidak
  String? _kriteriaRumah; // Sehat / Kurang Sehat
  String? _statusUp2k; // Ya / Tidak
  int? _idJenisUsahaUp2k;
  String? _statusKukl; // Ya / Tidak

  bool _isLoading = false;

  bool get _isEdit => widget.data != null;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _noKKController = TextEditingController(text: d?.noKK ?? widget.initialNoKK ?? '');
    _jumlahKKController = TextEditingController(text: d?.jumlahKK?.toString() ?? '');
    _jumlahBalitaLakiController = TextEditingController(text: d?.jumlahBalitaLakiLaki?.toString() ?? '');
    _jumlahBalitaPerempuanController = TextEditingController(text: d?.jumlahBalitaPerempuan?.toString() ?? '');
    _jumlahPusController = TextEditingController(text: d?.jumlahPus?.toString() ?? '');
    _jumlahWusController = TextEditingController(text: d?.jumlahWus?.toString() ?? '');
    _jumlahButaController = TextEditingController(text: d?.jumlahButa?.toString() ?? '');
    _jumlahIbuHamilController = TextEditingController(text: d?.jumlahIbuHamil?.toString() ?? '');
    _jumlahIbuMenyusuiController = TextEditingController(text: d?.jumlahIbuMenyusui?.toString() ?? '');
    _jumlahLansiaController = TextEditingController(text: d?.jumlahLansia?.toString() ?? '');
    _jumlahGiziKurangController = TextEditingController(text: d?.jumlahGiziKurang?.toString() ?? '');
    _jumlahGiziBurukController = TextEditingController(text: d?.jumlahGiziBuruk?.toString() ?? '');
    _jumlahStuntingController = TextEditingController(text: d?.jumlahStunting?.toString() ?? '');
    _jumlahDisabilitasController = TextEditingController(text: d?.jumlahDisabilitas?.toString() ?? '');
    _jumlahJambanController = TextEditingController(text: d?.jumlahJamban?.toString() ?? '');

    _makananPokok = d?.makananPokok;
    _idJenisMakananPokok = d?.idJenisMakananPokok;
    _statusJamban = d?.statusJamban;
    _idSumberAir = d?.idSumberAir;
    _statusSampah = d?.statusTempatPembuanganSampah;
    _statusSPAL = d?.statusSaluranPembuangan;
    _statusP4k = d?.statusStickerP4k;
    _kriteriaRumah = d?.kriteriaRumah;
    _statusUp2k = d?.statusAktifitasUp2k;
    _idJenisUsahaUp2k = d?.idJenisUsahaUp2k;
    _statusKukl = d?.statusAktifitasKukl;

    // Preload references for dropdowns
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReferenceProvider>().loadReferences();
    });
  }

  @override
  void dispose() {
    _noKKController.dispose();
    _jumlahKKController.dispose();
    _jumlahBalitaLakiController.dispose();
    _jumlahBalitaPerempuanController.dispose();
    _jumlahPusController.dispose();
    _jumlahWusController.dispose();
    _jumlahButaController.dispose();
    _jumlahIbuHamilController.dispose();
    _jumlahIbuMenyusuiController.dispose();
    _jumlahLansiaController.dispose();
    _jumlahGiziKurangController.dispose();
    _jumlahGiziBurukController.dispose();
    _jumlahStuntingController.dispose();
    _jumlahDisabilitasController.dispose();
    _jumlahJambanController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final jumlahBalitaLaki = _parseInt(_jumlahBalitaLakiController.text) ?? 0;
    final jumlahBalitaPerempuan = _parseInt(_jumlahBalitaPerempuanController.text) ?? 0;

    // Kolom NOT NULL (tanpa default) wajib dikirim sebagai angka — gunakan 0 jika kosong.
    // Kolom nullable boleh null dan akan dihapus dari payload.
    // config_year tidak dikirim — server menetapkannya dari ConfigService
    // agar konsisten dengan tahun rekap dashboard.
    final data = <String, dynamic>{
      'no_kk': _noKKController.text.trim(),
      'jumlah_kk': _parseInt(_jumlahKKController.text),
      'jumlah_balita': jumlahBalitaLaki + jumlahBalitaPerempuan,
      'jumlah_balita_laki_laki': jumlahBalitaLaki > 0 ? jumlahBalitaLaki : null,
      'jumlah_balita_perempuan': jumlahBalitaPerempuan > 0 ? jumlahBalitaPerempuan : null,
      'jumlah_pus': _parseInt(_jumlahPusController.text) ?? 0,
      'jumlah_wus': _parseInt(_jumlahWusController.text) ?? 0,
      'jumlah_buta': _parseInt(_jumlahButaController.text) ?? 0,
      'jumlah_ibu_hamil': _parseInt(_jumlahIbuHamilController.text) ?? 0,
      'jumlah_ibu_menyusui': _parseInt(_jumlahIbuMenyusuiController.text) ?? 0,
      'jumlah_lansia': _parseInt(_jumlahLansiaController.text) ?? 0,
      'jumlah_gizi_kurang': _parseInt(_jumlahGiziKurangController.text),
      'jumlah_gizi_buruk': _parseInt(_jumlahGiziBurukController.text),
      'jumlah_stunting': _parseInt(_jumlahStuntingController.text),
      'jumlah_disabilitas': _parseInt(_jumlahDisabilitasController.text),
      'makanan_pokok': _makananPokok,
      'id_jenis_makanan_pokok': _idJenisMakananPokok,
      'status_jamban': _statusJamban,
      'jumlah_jamban': _parseInt(_jumlahJambanController.text),
      'id_sumber_air': _idSumberAir,
      'status_tempat_pembuangan_sampah': _statusSampah,
      'status_saluran_pembuangan': _statusSPAL,
      'status_sticker_p4k': _statusP4k,
      'kriteria_rumah': _kriteriaRumah,
      'status_aktifitas_up2k': _statusUp2k,
      'id_jenis_usaha_up2k': _idJenisUsahaUp2k,
      'status_aktifitas_kukl': _statusKukl,
    };

    data.removeWhere((key, value) => value == null || (value is String && value.isEmpty));

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      await client.post(ApiEndpoints.dasawismaKeluarga, data: data);

      if (!mounted) return;
      _showSnackbar(_isEdit ? 'Data kesehatan berhasil diperbarui' : 'Data kesehatan berhasil disimpan');
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
    final refs = context.watch<ReferenceProvider>().data;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Data Kesehatan Keluarga' : 'Data Kesehatan Keluarga')),
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
                readOnly: _isEdit,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'No. KK wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              _numberField(_jumlahKKController, 'Jumlah Anggota Keluarga (KK)'),
              const SizedBox(height: 20),

              _sectionHeader('Jumlah Balita', Icons.child_care_rounded),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _numberField(_jumlahBalitaLakiController, 'Balita Laki-laki')),
                  const SizedBox(width: 12),
                  Expanded(child: _numberField(_jumlahBalitaPerempuanController, 'Balita Perempuan')),
                ],
              ),
              const SizedBox(height: 4),
              _autoSumHint(),
              const SizedBox(height: 20),

              _sectionHeader('Data PUS & WUS', Icons.groups_rounded),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _numberField(_jumlahPusController, 'PUS')),
                  const SizedBox(width: 12),
                  Expanded(child: _numberField(_jumlahWusController, 'WUS')),
                ],
              ),
              const SizedBox(height: 12),
              _numberField(_jumlahButaController, 'Buta'),
              _numberField(_jumlahIbuHamilController, 'Ibu Hamil'),
              _numberField(_jumlahIbuMenyusuiController, 'Ibu Menyusui'),
              _numberField(_jumlahLansiaController, 'Lansia'),
              const SizedBox(height: 20),

              _sectionHeader('Gizi & Kesehatan', Icons.health_and_safety_rounded),
              const SizedBox(height: 12),
              _numberField(_jumlahGiziKurangController, 'Gizi Kurang'),
              _numberField(_jumlahGiziBurukController, 'Gizi Buruk'),
              _numberField(_jumlahStuntingController, 'Stunting'),
              _numberField(_jumlahDisabilitasController, 'Disabilitas'),
              const SizedBox(height: 20),

              _sectionHeader('Makanan Pokok', Icons.restaurant_rounded),
              const SizedBox(height: 12),
              _statusDropdown(
                'Makanan Pokok Sehari-hari *',
                _makananPokok,
                (v) => setState(() => _makananPokok = v),
                const ['Beras', 'Non Beras'],
                required: true,
              ),
              const SizedBox(height: 12),
              _refDropdown(
                'Jenis Makanan Pokok',
                _idJenisMakananPokok,
                (v) => setState(() => _idJenisMakananPokok = v),
                refs?.jenisMakananPokok,
              ),
              const SizedBox(height: 20),

              _sectionHeader('Sanitasi & Rumah', Icons.home_rounded),
              const SizedBox(height: 12),
              _statusDropdown(
                'Mempunyai Jamban Keluarga *',
                _statusJamban,
                (v) => setState(() => _statusJamban = v),
                const ['Ya', 'Tidak'],
                required: true,
              ),
              const SizedBox(height: 12),
              _numberField(_jumlahJambanController, 'Jumlah Jamban'),
              const SizedBox(height: 12),
              _refDropdown(
                'Sumber Air *',
                _idSumberAir,
                (v) => setState(() => _idSumberAir = v),
                refs?.sumberAir,
                required: true,
              ),
              const SizedBox(height: 12),
              _statusDropdown(
                'Memiliki Tempat Pembuangan Sampah *',
                _statusSampah,
                (v) => setState(() => _statusSampah = v),
                const ['Ya', 'Tidak'],
                required: true,
              ),
              const SizedBox(height: 12),
              _statusDropdown(
                'Saluran Pembuangan Air Limbah *',
                _statusSPAL,
                (v) => setState(() => _statusSPAL = v),
                const ['Ya', 'Tidak'],
                required: true,
              ),
              const SizedBox(height: 12),
              _statusDropdown(
                'Menempel Stiker P4K *',
                _statusP4k,
                (v) => setState(() => _statusP4k = v),
                const ['Ya', 'Tidak'],
                required: true,
              ),
              const SizedBox(height: 12),
              _statusDropdown(
                'Kriteria Rumah *',
                _kriteriaRumah,
                (v) => setState(() => _kriteriaRumah = v),
                const ['Sehat', 'Kurang Sehat'],
                required: true,
              ),
              const SizedBox(height: 20),

              _sectionHeader('UP2K & KUKL', Icons.storefront_rounded),
              const SizedBox(height: 12),
              _statusDropdown(
                'Aktivitas UP2K *',
                _statusUp2k,
                (v) => setState(() => _statusUp2k = v),
                const ['Tidak', 'Ya'],
                required: true,
              ),
              if (_statusUp2k == 'Ya') ...[
                const SizedBox(height: 12),
                _refDropdown(
                  'Jenis Usaha UP2K',
                  _idJenisUsahaUp2k,
                  (v) => setState(() => _idJenisUsahaUp2k = v),
                  refs?.jenisUsahaUp2k,
                ),
              ],
              const SizedBox(height: 12),
              _statusDropdown(
                'Aktivitas Usaha Kesehatan Lingkungan (KUKL) *',
                _statusKukl,
                (v) => setState(() => _statusKukl = v),
                const ['Tidak', 'Ya'],
                required: true,
              ),
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
                            Text('SIMPAN DATA'),
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

  Widget _autoSumHint() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'Total balita otomatis = Laki-laki + Perempuan',
        style: TextStyle(fontSize: 11, color: AppTheme.textHintOf(context)),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
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

  Widget _statusDropdown(
    String label,
    String? value,
    ValueChanged<String?> onChanged,
    List<String> options, {
    bool required = false,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.checklist_rounded)),
      items: [
        DropdownMenuItem(value: null, child: Text('- Pilih -', style: TextStyle(color: AppTheme.textHintOf(context)))),
        ...options.map((o) => DropdownMenuItem(value: o, child: Text(o))),
      ],
      onChanged: onChanged,
      validator: required ? (v) => v == null ? 'Wajib diisi' : null : null,
    );
  }

  Widget _refDropdown(
    String label,
    int? value,
    ValueChanged<int?> onChanged,
    List<ReferenceItem>? items, {
    bool required = false,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.list_alt_rounded)),
      items: [
        DropdownMenuItem(value: null, child: Text('- Pilih -', style: TextStyle(color: AppTheme.textHintOf(context)))),
        ...?items?.map((o) => DropdownMenuItem(value: o.id, child: Text(o.nama))),
      ],
      onChanged: onChanged,
      validator: required ? (v) => v == null ? 'Wajib diisi' : null : null,
    );
  }
}
