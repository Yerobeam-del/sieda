import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/storage/local_storage.dart';
import '../../../database/local_database.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/activity_service.dart';
import '../../../models/penduduk_model.dart';
import '../../../models/reference_model.dart';
import '../../../providers/reference_provider.dart';
import '../../../widgets/location_picker_widget.dart';

class PendudukFormScreen extends StatefulWidget {
  final PendudukModel? penduduk;
  final String? initialNik;

  const PendudukFormScreen({super.key, this.penduduk, this.initialNik});

  @override
  State<PendudukFormScreen> createState() => _PendudukFormScreenState();
}

class _PendudukFormScreenState extends State<PendudukFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nikController;
  late final TextEditingController _namaController;
  late final TextEditingController _tempatLahirController;
  late final TextEditingController _tanggalLahirController;
  late final TextEditingController _alamatController;
  late final TextEditingController _noHpController;
  late final TextEditingController _noRegistrasiController;

  // Dropdown values - Identitas
  String? _jenisKelamin;
  int? _idAgama;
  int? _idPendidikan;
  int? _idPekerjaan;
  int? _idStatusPerkawinan;
  int? _idPeranKeluarga;
  int? _idStatusKeluarga;

  // Dropdown values - PKK
  String? _statusAkseptor;
  int? _idJenisAkseptor;
  String? _statusPosyandu;
  final _frekuensiPosyanduController = TextEditingController();
  String? _statusPbkb;
  String? _statusTabungan;
  String? _statusKelompokBelajar;
  int? _idJenisKelompokBelajar;
  String? _statusPaud;
  String? _statusKegiatanKoperasi;
  int? _idJenisKoperasi;
  String? _statusKebutuhanKhusus;
  int? _idKebutuhanKhusus;

  bool _isLoading = false;
  bool _isSavingOffline = false;
  DateTime? _tanggalLahir;

  bool get _isEditing => widget.penduduk != null;

  @override
  void initState() {
    super.initState();
    final p = widget.penduduk;
    _nikController = TextEditingController(text: p?.nik ?? widget.initialNik ?? '');
    _namaController = TextEditingController(text: p?.nama ?? '');
    _tempatLahirController = TextEditingController(text: p?.tempatLahir ?? '');
    _tanggalLahirController = TextEditingController(text: p?.tanggalLahir ?? '');
    _alamatController = TextEditingController(text: p?.alamat ?? '');
    _noHpController = TextEditingController(text: p?.noHp ?? '');
    _noRegistrasiController = TextEditingController(text: p?.noRegistrasi ?? '');
    _frekuensiPosyanduController.text = p?.frekuensiPosyandu ?? '';

    _jenisKelamin = p?.jenisKelamin;
    _statusAkseptor = p?.statusAkseptor;
    _statusPosyandu = p?.statusPosyandu;
    _statusPbkb = p?.statusPbkb;
    _statusTabungan = p?.statusTabungan;
    _statusKelompokBelajar = p?.statusKelompokBelajar;
    _statusPaud = p?.statusPaud;
    _statusKegiatanKoperasi = p?.statusKegiatanKoperasi;
    _statusKebutuhanKhusus = p?.statusKebutuhanKhusus;

    // Load references
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReferenceProvider>().loadReferences();
    });
  }

  @override
  void dispose() {
    _nikController.dispose();
    _namaController.dispose();
    _tempatLahirController.dispose();
    _tanggalLahirController.dispose();
    _alamatController.dispose();
    _noHpController.dispose();
    _noRegistrasiController.dispose();
    _frekuensiPosyanduController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalLahir ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _tanggalLahir = picked;
        _tanggalLahirController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_jenisKelamin == null) {
      _showSnackbar('Pilih jenis kelamin');
      return;
    }

    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'nik': _nikController.text.trim(),
      'no_registrasi': _noRegistrasiController.text.trim(),
      'nama': _namaController.text.trim(),
      'tempat_lahir': _tempatLahirController.text.trim(),
      'tanggal_lahir': _tanggalLahirController.text.trim(),
      'jenis_kelamin': _jenisKelamin,
      'alamat': _alamatController.text.trim(),
      'no_hp': _noHpController.text.trim(),
      // Referensi
      'id_agama': _idAgama,
      'id_jenjang_pendidikan': _idPendidikan,
      'id_pekerjaan': _idPekerjaan,
      'id_status_perkawinan': _idStatusPerkawinan,
      'id_peran_keluarga': _idPeranKeluarga,
      'id_status_keluarga': _idStatusKeluarga,
      // PKK Status
      'status_akseptor': _statusAkseptor,
      'id_jenis_akseptor': _statusAkseptor == 'Ya' ? _idJenisAkseptor : null,
      'status_posyandu': _statusPosyandu,
      'frekuensi_posyandu': _statusPosyandu == 'Ya' ? _frekuensiPosyanduController.text.trim() : null,
      'status_pbkb': _statusPbkb,
      'status_tabungan': _statusTabungan,
      'status_kelompok_belajar': _statusKelompokBelajar,
      'id_jenis_kelompok_belajar': _statusKelompokBelajar == 'Ya' ? _idJenisKelompokBelajar : null,
      'status_paud': _statusPaud,
      'status_kegiatan_koperasi': _statusKegiatanKoperasi,
      'id_jenis_koperasi': _statusKegiatanKoperasi == 'Ya' ? _idJenisKoperasi : null,
      'status_kebutuhan_khusus': _statusKebutuhanKhusus,
      'id_kebutuhan_khusus': _statusKebutuhanKhusus == 'Ya' ? _idKebutuhanKhusus : null,
    };

    // Remove null values for cleaner request
    data.removeWhere((key, value) => value == null);

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);

      if (_isEditing) {
        await client.put(ApiEndpoints.pendudukDetail(widget.penduduk!.nik), data: data);
      } else {
        await client.post(ApiEndpoints.penduduk, data: data);
      }

      if (!mounted) return;
      _showSnackbar(_isEditing ? 'Penduduk berhasil diperbarui' : 'Penduduk berhasil ditambahkan');
      ActivityService().logSave(
        tipe: 'Penduduk',
        nama: _namaController.text.trim(),
        identifier: _nikController.text.trim(),
        isEdit: _isEditing,
        isOnline: true,
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 422) {
        _showSnackbar('Validasi gagal: ${e.friendlyMessage}');
      } else {
        _showSnackbar(e.friendlyMessage);
        _offerOfflineSave(data);
      }
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
        content: const Text('Data akan disimpan di perangkat dan dikirim saat tersambung internet.'),
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
      await LocalDatabase().savePendingPenduduk(data);
      ActivityService().logSave(
        tipe: 'Penduduk',
        nama: data['nama'] ?? '',
        identifier: data['nik'],
        isEdit: _isEditing,
        isOnline: false,
      );
      setState(() => _isSavingOffline = false);
      if (!mounted) return;
      _showSnackbar('Data disimpan offline. Akan dikirim saat online.');
      Navigator.of(context).pop(true);
    }
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityService>().isOnline;
    final refProv = context.watch<ReferenceProvider>();
    final refs = refProv.data;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Penduduk' : 'Tambah Penduduk'),
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
              // ============ BAGIAN 1: DATA WAJIB ============
              _sectionHeader('Data Identitas'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _noRegistrasiController,
                decoration: const InputDecoration(
                  labelText: 'No. Registrasi',
                  hintText: 'Nomor registrasi (opsional)',
                  prefixIcon: Icon(Icons.tag_rounded),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nikController,
                decoration: const InputDecoration(
                  labelText: 'NIK *',
                  hintText: '16 digit NIK',
                  prefixIcon: Icon(Icons.badge_outlined),
                  counterText: '',
                ),
                maxLength: 16,
                keyboardType: TextInputType.number,
                readOnly: _isEditing,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'NIK wajib diisi';
                  if (v.trim().length != 16) return 'NIK harus 16 digit';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap *',
                  hintText: 'Nama sesuai KTP',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Jenis Kelamin
              Text('Jenis Kelamin *', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _genderCard('L', 'Laki-laki', Icons.male_rounded, AppTheme.male)),
                  const SizedBox(width: 12),
                  Expanded(child: _genderCard('P', 'Perempuan', Icons.female_rounded, AppTheme.female)),
                ],
              ),
              const SizedBox(height: 20),

              // ============ BAGIAN 2: DATA TAMBAHAN ============
              _sectionHeader('Data Tambahan'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _tempatLahirController,
                decoration: const InputDecoration(
                  labelText: 'Tempat Lahir',
                  prefixIcon: Icon(Icons.location_city_outlined),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _tanggalLahirController,
                readOnly: true,
                onTap: _pickDate,
                decoration: InputDecoration(
                  labelText: 'Tanggal Lahir',
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.date_range_rounded),
                    onPressed: _pickDate,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Agama
              _refDropdown(
                context,
                label: 'Agama',
                value: _idAgama,
                items: refs?.agama ?? [],
                onChanged: (v) => setState(() => _idAgama = v),
                icon: Icons.church_outlined,
              ),
              const SizedBox(height: 12),

              // Pendidikan
              _refDropdown(
                context,
                label: 'Pendidikan',
                value: _idPendidikan,
                items: refs?.pendidikan ?? [],
                onChanged: (v) => setState(() => _idPendidikan = v),
                icon: Icons.school_outlined,
              ),
              const SizedBox(height: 12),

              // Pekerjaan
              _refDropdown(
                context,
                label: 'Pekerjaan',
                value: _idPekerjaan,
                items: refs?.pekerjaan ?? [],
                onChanged: (v) => setState(() => _idPekerjaan = v),
                icon: Icons.work_outline,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _noHpController,
                decoration: const InputDecoration(
                  labelText: 'No. HP',
                  hintText: '08xxxxxxxxxx',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Location Picker — GPS + Mini Map
              LocationPickerWidget(
                addressInitialValue: _alamatController.text,
                onAddressChanged: (v) {
                  _alamatController.text = v;
                  _alamatController.selection = TextSelection.fromPosition(
                    TextPosition(offset: v.length),
                  );
                },
              ),
              const SizedBox(height: 20),

              // ============ BAGIAN 3: STATUS KELUARGA ============
              _sectionHeader('Status Keluarga'),
              const SizedBox(height: 12),

              _refDropdown(
                context,
                label: 'Status Perkawinan',
                value: _idStatusPerkawinan,
                items: refs?.statusPerkawinan ?? [],
                onChanged: (v) => setState(() => _idStatusPerkawinan = v),
                icon: Icons.favorite_outline_rounded,
              ),
              const SizedBox(height: 12),

              _refDropdown(
                context,
                label: 'Peran dalam Keluarga',
                value: _idPeranKeluarga,
                items: refs?.peranKeluarga ?? [],
                onChanged: (v) => setState(() => _idPeranKeluarga = v),
                icon: Icons.people_outline_rounded,
              ),
              const SizedBox(height: 12),

              _refDropdown(
                context,
                label: 'Status dalam Keluarga',
                value: _idStatusKeluarga,
                items: refs?.statusKeluarga ?? [],
                onChanged: (v) => setState(() => _idStatusKeluarga = v),
                icon: Icons.family_restroom_outlined,
              ),
              const SizedBox(height: 20),

              // ============ BAGIAN 4: PROGRAM PKK ============
              _sectionHeader('Program PKK'),
              const SizedBox(height: 8),
              Text(
                'Status program PKK warga. Pilih "Ya" untuk mengisi detail lanjutan.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textHint),
              ),
              const SizedBox(height: 12),

              // Akseptor KB
              _yesNoToggle(context, 'Akseptor KB', _statusAkseptor, (v) => setState(() {
                _statusAkseptor = v;
                if (v != 'Ya') _idJenisAkseptor = null;
              })),
              if (_statusAkseptor == 'Ya') ...[
                const SizedBox(height: 8),
                _refDropdown(
                  context,
                  label: 'Jenis Akseptor KB',
                  value: _idJenisAkseptor,
                  items: refs?.jenisAkseptor ?? [],
                  onChanged: (v) => setState(() => _idJenisAkseptor = v),
                  icon: Icons.medical_services_outlined,
                ),
              ],
              const SizedBox(height: 12),

              // Posyandu
              _yesNoToggle(context, 'Mengikuti Posyandu', _statusPosyandu, (v) => setState(() {
                _statusPosyandu = v;
                if (v != 'Ya') _frekuensiPosyanduController.clear();
              })),
              if (_statusPosyandu == 'Ya') ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _frekuensiPosyanduController,
                  decoration: const InputDecoration(
                    labelText: 'Frekuensi Kunjungan',
                    hintText: 'Contoh: 12 kali/tahun',
                    prefixIcon: Icon(Icons.repeat_rounded),
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // BKB
              _yesNoToggle(context, 'BKB (Bina Keluarga Balita)', _statusPbkb, (v) => setState(() => _statusPbkb = v)),
              const SizedBox(height: 12),

              // Tabungan
              _yesNoToggle(context, 'Memiliki Tabungan', _statusTabungan, (v) => setState(() => _statusTabungan = v)),
              const SizedBox(height: 12),

              // Kelompok Belajar
              _yesNoToggle(context, 'Kelompok Belajar', _statusKelompokBelajar, (v) => setState(() {
                _statusKelompokBelajar = v;
                if (v != 'Ya') _idJenisKelompokBelajar = null;
              })),
              if (_statusKelompokBelajar == 'Ya') ...[
                const SizedBox(height: 8),
                _refDropdown(
                  context,
                  label: 'Jenis Kelompok Belajar',
                  value: _idJenisKelompokBelajar,
                  items: refs?.jenisKelompokBelajar ?? [],
                  onChanged: (v) => setState(() => _idJenisKelompokBelajar = v),
                  icon: Icons.book_outlined,
                ),
              ],
              const SizedBox(height: 12),

              // PAUD
              _yesNoToggle(context, 'PAUD/Sejenis', _statusPaud, (v) => setState(() => _statusPaud = v)),
              const SizedBox(height: 12),

              // Koperasi
              _yesNoToggle(context, 'Kegiatan Koperasi', _statusKegiatanKoperasi, (v) => setState(() {
                _statusKegiatanKoperasi = v;
                if (v != 'Ya') _idJenisKoperasi = null;
              })),
              if (_statusKegiatanKoperasi == 'Ya') ...[
                const SizedBox(height: 8),
                _refDropdown(
                  context,
                  label: 'Jenis Koperasi',
                  value: _idJenisKoperasi,
                  items: refs?.jenisKoperasi ?? [],
                  onChanged: (v) => setState(() => _idJenisKoperasi = v),
                  icon: Icons.store_outlined,
                ),
              ],
              const SizedBox(height: 12),

              // Kebutuhan Khusus
              _yesNoToggle(context, 'Kebutuhan Khusus', _statusKebutuhanKhusus, (v) => setState(() {
                _statusKebutuhanKhusus = v;
                if (v != 'Ya') _idKebutuhanKhusus = null;
              })),
              if (_statusKebutuhanKhusus == 'Ya') ...[
                const SizedBox(height: 8),
                _refDropdown(
                  context,
                  label: 'Jenis Kebutuhan Khusus',
                  value: _idKebutuhanKhusus,
                  items: refs?.kebutuhanKhusus ?? [],
                  onChanged: (v) => setState(() => _idKebutuhanKhusus = v),
                  icon: Icons.accessibility_new_rounded,
                ),
              ],
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: (_isLoading || _isSavingOffline) ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isEditing ? Icons.save_rounded : Icons.person_add_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(_isEditing ? 'SIMPAN PERUBAHAN' : 'TAMBAH PENDUDUK'),
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
                      Text('Menyimpan offline...', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(width: 3, height: 18, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _genderCard(String value, String label, IconData icon, Color color) {
    final selected = _jenisKelamin == value;
    return GestureDetector(
      onTap: () => setState(() => _jenisKelamin = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppTheme.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : AppTheme.textHint, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? color : AppTheme.textPrimary,
            )),
          ],
        ),
      ),
    );
  }

  Widget _refDropdown(
    BuildContext context, {
    required String label,
    required int? value,
    required List<ReferenceItem> items,
    required ValueChanged<int?> onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: [
        DropdownMenuItem<int>(
          value: null,
          child: Text('- Pilih $label -', style: const TextStyle(color: AppTheme.textHint)),
        ),
        ...items.map((item) => DropdownMenuItem<int>(
              value: item.id,
              child: Text(item.nama),
            )),
      ],
      onChanged: onChanged,
    );
  }

  Widget _yesNoToggle(BuildContext context, String label, String? currentValue, ValueChanged<String> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
          ),
          _toggleChip('Ya', currentValue == 'Ya', AppTheme.success, () => onChanged('Ya')),
          const SizedBox(width: 8),
          _toggleChip('Tidak', currentValue == 'Tidak', AppTheme.textHint, () => onChanged('Tidak')),
        ],
      ),
    );
  }

  Widget _toggleChip(String label, bool selected, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? color : AppTheme.textHint,
          ),
        ),
      ),
    );
  }
}
