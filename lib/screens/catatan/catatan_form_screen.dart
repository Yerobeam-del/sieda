import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/api/api_exception.dart';
import '../../core/storage/local_storage.dart';
import '../../database/local_database.dart';
import '../../services/connectivity_service.dart';
import '../../services/activity_service.dart';
import '../../models/catatan_model.dart';

class CatatanFormScreen extends StatefulWidget {
  final CatatanKelahiranKematianModel? catatan;

  const CatatanFormScreen({super.key, this.catatan});

  @override
  State<CatatanFormScreen> createState() => _CatatanFormScreenState();
}

class _CatatanFormScreenState extends State<CatatanFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController _nikIbuController;
  late final TextEditingController _nikSuamiController;
  late final TextEditingController _noKkController;
  DateTime? _tanggalHamil;
  DateTime? _tanggalPerkiraanLahir;
  late final TextEditingController _tanggalHamilController;
  late final TextEditingController _tanggalMelahirkanController;
  late final TextEditingController _tanggalNifasController;
  late final TextEditingController _namaBayiController;
  late final TextEditingController _tanggalLahirBayiController;
  late final TextEditingController _noAkteController;
  late final TextEditingController _namaMeninggalController;
  late final TextEditingController _tanggalMeninggalController;
  late final TextEditingController _sebabMeninggalController;
  late final TextEditingController _keteranganController;

  // Dropdown values
  String? _statusIbu; // hamil, melahirkan, nifas, meninggal
  String? _jenisKelaminBayi; // L, P
  String? _akteKelahiran; // Ada, Tidak
  String? _statusKematian; // ibu, bayi, balita
  String? _jenisKelaminMeninggal; // L, P

  bool _isLoading = false;

  DateTime? _tanggalMelahirkan;
  DateTime? _tanggalNifas;
  DateTime? _tanggalLahirBayi;
  DateTime? _tanggalMeninggal;

  bool get _isEditing => widget.catatan != null;

  @override
  void initState() {
    super.initState();
    final c = widget.catatan;

    _nikIbuController = TextEditingController(text: c?.idWargaIbu ?? '');
    _nikSuamiController = TextEditingController(text: c?.idWargaSuami ?? '');
    _noKkController = TextEditingController(text: c?.noKk ?? '');
    final tglHamil = c?.tanggalHamil;
    _tanggalHamil = tglHamil != null ? DateTime.tryParse(tglHamil) : null;
    final tpl = c?.tanggalPerkiraanLahir;
    _tanggalPerkiraanLahir = tpl != null ? DateTime.tryParse(tpl) : null;
    _tanggalHamilController = TextEditingController(
      text: c?.tanggalHamil ?? '',
    );
    _tanggalMelahirkanController = TextEditingController(text: c?.tanggalMelahirkan ?? '');
    _tanggalNifasController = TextEditingController(text: c?.tanggalNifasSelesai ?? '');
    _namaBayiController = TextEditingController(text: c?.namaBayi ?? '');
    _tanggalLahirBayiController = TextEditingController(text: c?.tanggalLahirBayi ?? '');
    _noAkteController = TextEditingController(text: c?.noAkteKelahiran ?? '');
    _namaMeninggalController = TextEditingController(text: c?.namaMeninggal ?? '');
    _tanggalMeninggalController = TextEditingController(text: c?.tanggalMeninggal ?? '');
    _sebabMeninggalController = TextEditingController(text: c?.sebabMeninggal ?? '');
    _keteranganController = TextEditingController(text: c?.keterangan ?? '');

    _statusIbu = c?.statusIbu;
    _jenisKelaminBayi = c?.jenisKelaminBayi;
    _akteKelahiran = c?.akteKelahiran ?? 'Tidak';
    _statusKematian = c?.statusKematian;
    _jenisKelaminMeninggal = c?.jenisKelaminMeninggal;
  }

  @override
  void dispose() {
    _nikIbuController.dispose();
    _nikSuamiController.dispose();
    _noKkController.dispose();

    _tanggalHamilController.dispose();
    _tanggalMelahirkanController.dispose();
    _tanggalNifasController.dispose();
    _namaBayiController.dispose();
    _tanggalLahirBayiController.dispose();
    _noAkteController.dispose();
    _namaMeninggalController.dispose();
    _tanggalMeninggalController.dispose();
    _sebabMeninggalController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller, DateTime? currentDate, ValueChanged<DateTime> onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      onPicked(picked);
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nikIbuController.text.trim().isEmpty) {
      _showSnackbar('NIK Ibu wajib diisi');
      return;
    }

    setState(() => _isLoading = true);

    final data = <String, dynamic>{
      'id_warga_ibu': _nikIbuController.text.trim(),
      'id_warga_suami': _nikSuamiController.text.trim().isNotEmpty ? _nikSuamiController.text.trim() : null,
      'no_kk': _noKkController.text.trim().isNotEmpty ? _noKkController.text.trim() : null,
      'status_ibu': _statusIbu,
      'tanggal_perkiraan_lahir': _tanggalPerkiraanLahir != null
          ? DateFormat('yyyy-MM-dd').format(_tanggalPerkiraanLahir!)
          : null,
      'tanggal_hamil': _tanggalHamil != null
          ? DateFormat('yyyy-MM-dd').format(_tanggalHamil!)
          : null,
      'tanggal_melahirkan': _tanggalMelahirkanController.text.trim().isNotEmpty ? _tanggalMelahirkanController.text.trim() : null,
      'tanggal_nifas_selesai': _tanggalNifasController.text.trim().isNotEmpty ? _tanggalNifasController.text.trim() : null,
      // Skema baru: data kelahiran & kematian berprefix kelahiran_*/kematian_*
      'kelahiran_status': _namaBayiController.text.trim().isNotEmpty ? 'Ada' : null,
      'kelahiran_nama_bayi': _namaBayiController.text.trim().isNotEmpty ? _namaBayiController.text.trim() : null,
      'kelahiran_jenis_kelamin': _jenisKelaminBayi,
      'kelahiran_tanggal': _tanggalLahirBayiController.text.trim().isNotEmpty ? _tanggalLahirBayiController.text.trim() : null,
      'kelahiran_status_akte': _akteKelahiran,
      'kelahiran_no_akte': _noAkteController.text.trim().isNotEmpty ? _noAkteController.text.trim() : null,
      'kematian_status': _statusKematian,
      'kematian_nama': _namaMeninggalController.text.trim().isNotEmpty ? _namaMeninggalController.text.trim() : null,
      'kematian_jenis_kelamin': _jenisKelaminMeninggal,
      'kematian_tanggal': _tanggalMeninggalController.text.trim().isNotEmpty ? _tanggalMeninggalController.text.trim() : null,
      'kematian_sebab': _sebabMeninggalController.text.trim().isNotEmpty ? _sebabMeninggalController.text.trim() : null,
      'keterangan': _keteranganController.text.trim().isNotEmpty ? _keteranganController.text.trim() : null,
      'config_year': DateTime.now().year,
    };

    // Remove null values
    data.removeWhere((key, value) => value == null);

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);

      if (_isEditing) {
        await client.put(ApiEndpoints.catatanDetail(widget.catatan!.id), data: data);
      } else {
        await client.post(ApiEndpoints.catatanKelahiranKematian, data: data);
      }

      if (!mounted) return;
      _showSnackbar(_isEditing ? 'Catatan berhasil diperbarui' : 'Catatan berhasil ditambahkan');
      ActivityService().logSave(
        tipe: 'Catatan',
        nama: _nikIbuController.text.trim(),
        identifier: _statusIbu ?? '',
        isEdit: _isEditing,
        isOnline: true,
      );
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
      // Sertakan id catatan agar saat sinkron mode edit memakai PUT ke detail
      // (bukan CREATE) — mencegah duplikat catatan di server.
      if (_isEditing) data['id'] = widget.catatan!.id;
      await LocalDatabase().savePendingCatatan(data, action: _isEditing ? 'UPDATE' : 'CREATE');
      ActivityService().logSave(
        tipe: 'Catatan',
        nama: data['id_warga_ibu'] ?? '',
        identifier: data['status_ibu'] ?? '',
        isEdit: _isEditing,
        isOnline: false,
      );
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Catatan' : 'Tambah Catatan'),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ============ SECTION 1: DATA IBU ============
              _sectionHeader('Data Ibu', Icons.person_rounded, AppTheme.female),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nikIbuController,
                decoration: const InputDecoration(
                  labelText: 'NIK Ibu *',
                  hintText: 'NIK yang sudah terdaftar',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'NIK Ibu wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // ============ SECTION 2: DATA SUAMI ============
              _sectionHeader('Data Suami', Icons.person_rounded, AppTheme.male),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nikSuamiController,
                decoration: const InputDecoration(
                  labelText: 'NIK Suami',
                  hintText: 'NIK yang sudah terdaftar (opsional)',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _noKkController,
                decoration: const InputDecoration(
                  labelText: 'No. KK',
                  hintText: 'Nomor Kartu Keluarga',
                  prefixIcon: Icon(Icons.family_restroom_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // ============ SECTION 3: STATUS KEHAMILAN ============
              _sectionHeader('Status Kehamilan / Ibu', Icons.health_and_safety_rounded, AppTheme.female),
              const SizedBox(height: 12),

              Text('Status Ibu *', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13, color: AppTheme.textSecondaryOf(context))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statusChip('Hamil', 'hamil', Icons.favorite_rounded, AppTheme.female),
                  _statusChip('Melahirkan', 'melahirkan', Icons.child_care_rounded, AppTheme.success),
                  _statusChip('Nifas', 'nifas', Icons.healing_rounded, AppTheme.info),
                  _statusChip('Meninggal', 'meninggal', Icons.warning_amber_rounded, AppTheme.error),
                ],
              ),
              const SizedBox(height: 16),

              if (_statusIbu == 'hamil') ...[
                _dateField(_tanggalHamilController, 'Tanggal Hamil (HPHT) *', _tanggalHamil, (d) {
                  setState(() {
                    _tanggalHamil = d;
                    // Aturan Naegele: HPHT + 9 bulan + 7 hari
                    _tanggalPerkiraanLahir = DateTime(d.year, d.month + 9, d.day + 7);
                  });
                }),
                if (_tanggalPerkiraanLahir != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Perkiraan lahir: ${DateFormat('dd MMMM yyyy', 'id').format(_tanggalPerkiraanLahir!)}',
                    style: TextStyle(fontSize: 12, color: AppTheme.primary),
                  ),
                ],
              ],
              if (_statusIbu == 'melahirkan' || _statusIbu == 'nifas') ...[
                _dateField(_tanggalMelahirkanController, 'Tanggal Melahirkan', _tanggalMelahirkan, (d) => _tanggalMelahirkan = d),
              ],
              if (_statusIbu == 'nifas') ...[
                const SizedBox(height: 12),
                _dateField(_tanggalNifasController, 'Tanggal Nifas Selesai', _tanggalNifas, (d) => _tanggalNifas = d),
              ],
              const SizedBox(height: 20),

              // ============ SECTION 4: DATA BAYI ============
              _sectionHeader('Data Bayi', Icons.child_care_rounded, AppTheme.success),
              const SizedBox(height: 12),
              Text(
                'Isi jika ibu sudah melahirkan atau ada data bayi.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textHintOf(context)),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _namaBayiController,
                decoration: const InputDecoration(
                  labelText: 'Nama Bayi',
                  hintText: 'Nama bayi (jika sudah lahir)',
                  prefixIcon: Icon(Icons.child_care_rounded),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),

              Text('Jenis Kelamin Bayi', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13, color: AppTheme.textSecondaryOf(context))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _genderCard('L', 'Laki-laki', Icons.male_rounded, AppTheme.male, _jenisKelaminBayi, (v) => _jenisKelaminBayi = v)),
                  const SizedBox(width: 12),
                  Expanded(child: _genderCard('P', 'Perempuan', Icons.female_rounded, AppTheme.female, _jenisKelaminBayi, (v) => _jenisKelaminBayi = v)),
                ],
              ),
              const SizedBox(height: 12),

              _dateField(_tanggalLahirBayiController, 'Tanggal Lahir Bayi', _tanggalLahirBayi, (d) => _tanggalLahirBayi = d),
              const SizedBox(height: 12),

              Text('Akte Kelahiran', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13, color: AppTheme.textSecondaryOf(context))),
              const SizedBox(height: 8),
              Row(
                children: [
                  _toggleChip('Ada', _akteKelahiran == 'Ada', AppTheme.success, () => setState(() => _akteKelahiran = 'Ada')),
                  const SizedBox(width: 8),
                  _toggleChip('Tidak', _akteKelahiran == 'Tidak', AppTheme.textHintOf(context), () => setState(() => _akteKelahiran = 'Tidak')),
                ],
              ),
              if (_akteKelahiran == 'Ada') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noAkteController,
                  decoration: const InputDecoration(
                    labelText: 'No. Akte Kelahiran',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // ============ SECTION 5: DATA KEMATIAN ============
              _sectionHeader('Data Kematian', Icons.warning_amber_rounded, AppTheme.error),
              const SizedBox(height: 12),
              Text(
                'Isi jika ada kematian ibu, bayi, atau balita.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textHintOf(context)),
              ),
              const SizedBox(height: 8),

              Text('Status Kematian', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13, color: AppTheme.textSecondaryOf(context))),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _toggleChip('Ibu', _statusKematian == 'Ibu', AppTheme.error, () => setState(() => _statusKematian = 'Ibu')),
                  _toggleChip('Bayi', _statusKematian == 'Bayi', AppTheme.error, () => setState(() => _statusKematian = 'Bayi')),
                  _toggleChip('Balita', _statusKematian == 'Balita', AppTheme.error, () => setState(() => _statusKematian = 'Balita')),
                ],
              ),

              if (_statusKematian != null) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _namaMeninggalController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Meninggal',
                    prefixIcon: Icon(Icons.person_off_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),

                Text('Jenis Kelamin', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13, color: AppTheme.textSecondaryOf(context))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _genderCard('L', 'Laki-laki', Icons.male_rounded, AppTheme.male, _jenisKelaminMeninggal, (v) => _jenisKelaminMeninggal = v)),
                    const SizedBox(width: 12),
                    Expanded(child: _genderCard('P', 'Perempuan', Icons.female_rounded, AppTheme.female, _jenisKelaminMeninggal, (v) => _jenisKelaminMeninggal = v)),
                  ],
                ),
                const SizedBox(height: 12),

                _dateField(_tanggalMeninggalController, 'Tanggal Meninggal', _tanggalMeninggal, (d) => _tanggalMeninggal = d),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _sebabMeninggalController,
                  decoration: const InputDecoration(
                    labelText: 'Sebab Meninggal',
                    hintText: 'Penyebab kematian',
                    prefixIcon: Icon(Icons.medical_services_outlined),
                  ),
                  maxLines: 2,
                ),
              ],
              const SizedBox(height: 20),

              // ============ KETERANGAN ============
              _sectionHeader('Keterangan', Icons.notes_rounded, AppTheme.textHintOf(context)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _keteranganController,
                decoration: const InputDecoration(
                  labelText: 'Keterangan Tambahan',
                  hintText: 'Catatan tambahan (opsional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Submit
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
                            Text(_isEditing ? 'SIMPAN PERUBAHAN' : 'TAMBAH CATATAN'),
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

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _statusChip(String label, String value, IconData icon, Color color) {
    final selected = _statusIbu == value;
    return GestureDetector(
      onTap: () => setState(() => _statusIbu = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppTheme.borderOf(context), width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? color : AppTheme.textHintOf(context)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, color: selected ? color : AppTheme.textPrimaryOf(context))),
          ],
        ),
      ),
    );
  }

  Widget _dateField(TextEditingController controller, String label, DateTime? currentDate, ValueChanged<DateTime> onPicked) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _pickDate(controller, currentDate, onPicked),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        suffixIcon: IconButton(
          icon: const Icon(Icons.date_range_rounded),
          onPressed: () => _pickDate(controller, currentDate, onPicked),
        ),
      ),
    );
  }

  Widget _genderCard(String value, String label, IconData icon, Color color, String? currentValue, ValueChanged<String> onChanged) {
    final selected = currentValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppTheme.borderOf(context), width: selected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? color : AppTheme.textHintOf(context)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, color: selected ? color : AppTheme.textPrimaryOf(context))),
          ],
        ),
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
          color: selected ? color.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : Colors.transparent, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, color: selected ? color : AppTheme.textHintOf(context)),
        ),
      ),
    );
  }
}
