int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int? _parseIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    return parsed;
  }
  return null;
}

class CatatanKelahiranKematianModel {
  final int id;
  final String? idWargaIbu;
  final String? idWargaSuami;
  final String? noKk;
  final int? idGroupDasawisma;
  final String? statusIbu;
  final int? bulanHamil;
  final String? tanggalHamil;
  final String? tanggalPerkiraanLahir;
  final String? tanggalMelahirkan;
  final String? tanggalNifasSelesai;

  // Data Bayi
  final String? namaBayi;
  final String? jenisKelaminBayi;
  final String? tanggalLahirBayi;
  final String? akteKelahiran;
  final String? noAkteKelahiran;

  // Data Kematian
  final String? statusKematian;
  final String? namaMeninggal;
  final String? jenisKelaminMeninggal;
  final String? tanggalMeninggal;
  final String? sebabMeninggal;

  // Tambahan
  final int configYear;
  final String? keterangan;
  final bool active;

  // Nested relations (diisi dari parser)
  final String? namaIbu;
  final String? nikIbu;
  final String? namaSuami;
  final String? nikSuami;
  final String? namaKelompok;
  final String? namaDusun;

  /// true bila record ini berasal dari antrian offline (belum tersinkron
  /// ke server) — dipakai UI untuk menampilkan badge "Menunggu sinkron".
  final bool isPendingSync;

  CatatanKelahiranKematianModel({
    required this.id,
    this.idWargaIbu,
    this.idWargaSuami,
    this.noKk,
    this.idGroupDasawisma,
    this.statusIbu,
    this.bulanHamil,
    this.tanggalHamil,
    this.tanggalPerkiraanLahir,
    this.tanggalMelahirkan,
    this.tanggalNifasSelesai,
    this.namaBayi,
    this.jenisKelaminBayi,
    this.tanggalLahirBayi,
    this.akteKelahiran,
    this.noAkteKelahiran,
    this.statusKematian,
    this.namaMeninggal,
    this.jenisKelaminMeninggal,
    this.tanggalMeninggal,
    this.sebabMeninggal,
    this.configYear = 0,
    this.keterangan,
    this.active = true,
    this.namaIbu,
    this.nikIbu,
    this.namaSuami,
    this.nikSuami,
    this.namaKelompok,
    this.namaDusun,
    this.isPendingSync = false,
  });

  factory CatatanKelahiranKematianModel.fromJson(
    Map<String, dynamic> json, {
    bool isPendingSync = false,
  }) {
    // Extract nested relations
    String? extractName(dynamic val) {
      if (val is Map) return val['nama']?.toString();
      return val?.toString();
    }

    String? extractNik(dynamic val) {
      if (val is Map) return val['nik']?.toString();
      return null;
    }

    // Parse nested ibu
    final ibuData = json['ibu'];
    final namaIbu = extractName(ibuData);
    final nikIbu = extractNik(ibuData) ?? json['id_warga_ibu']?.toString();

    // Parse nested suami
    final suamiData = json['suami'];
    final namaSuami = extractName(suamiData);
    final nikSuami = extractNik(suamiData) ?? json['id_warga_suami']?.toString();

    // Parse nested kelompokDasawisma
    String? namaKelompok;
    String? namaDusun;
    if (json['kelompok_dasawisma'] is Map) {
      final kd = json['kelompok_dasawisma'] as Map<String, dynamic>;
      namaKelompok = kd['nama']?.toString();
      if (kd['dusun'] is Map) {
        namaDusun = (kd['dusun'] as Map)['nama']?.toString();
      }
    } else if (json['group_dasawisma'] is Map) {
      final kd = json['group_dasawisma'] as Map<String, dynamic>;
      namaKelompok = kd['nama']?.toString();
    }

    // Parse fallback names from API (some endpoints return flat nama_ibu, nama_suami)
    final fallbackNamaIbu = json['nama_ibu']?.toString() ?? namaIbu;
    final fallbackNamaSuami = json['nama_suami']?.toString() ?? namaSuami;

    // Skema resource baru: data bersarang di data_ibu / data_kelahiran /
    // data_kematian / periode. Fallback tetap mendukung skema lama (flat).
    Map<String, dynamic>? nested(String key) {
      final v = json[key];
      return v is Map<String, dynamic> ? v : null;
    }

    final dataIbu = nested('data_ibu');
    final dataKelahiran = nested('data_kelahiran');
    final dataKematian = nested('data_kematian');

    return CatatanKelahiranKematianModel(
      id: _parseInt(json['id']),
      idWargaIbu: json['id_warga_ibu']?.toString(),
      idWargaSuami: json['id_warga_suami']?.toString(),
      noKk: json['no_kk']?.toString(),
      idGroupDasawisma:
          _parseIntNullable(json['id_kelompok_dasawisma'] ?? json['id_group_dasawisma']),
      statusIbu: dataIbu?['status_ibu']?.toString() ?? json['status_ibu']?.toString(),
      bulanHamil: _parseIntNullable(json['bulan_hamil']),
      tanggalHamil: dataIbu?['tanggal_hamil']?.toString() ?? json['tanggal_hamil']?.toString(),
      tanggalPerkiraanLahir:
          dataIbu?['tanggal_perkiraan_lahir']?.toString() ?? json['tanggal_perkiraan_lahir']?.toString(),
      tanggalMelahirkan:
          dataIbu?['tanggal_melahirkan']?.toString() ?? json['tanggal_melahirkan']?.toString(),
      tanggalNifasSelesai:
          dataIbu?['tanggal_nifas_selesai']?.toString() ?? json['tanggal_nifas_selesai']?.toString(),
      namaBayi: dataKelahiran?['nama_bayi']?.toString() ?? json['nama_bayi']?.toString(),
      jenisKelaminBayi:
          dataKelahiran?['jenis_kelamin']?.toString() ?? json['jenis_kelamin_bayi']?.toString(),
      tanggalLahirBayi:
          dataKelahiran?['tanggal']?.toString() ?? json['tanggal_lahir_bayi']?.toString(),
      akteKelahiran:
          dataKelahiran?['status_akte']?.toString() ?? json['akte_kelahiran']?.toString(),
      noAkteKelahiran:
          dataKelahiran?['no_akte']?.toString() ?? json['no_akte_kelahiran']?.toString(),
      statusKematian: dataKematian?['status']?.toString() ?? json['status_kematian']?.toString(),
      namaMeninggal: dataKematian?['nama']?.toString() ?? json['nama_meninggal']?.toString(),
      jenisKelaminMeninggal:
          dataKematian?['jenis_kelamin']?.toString() ?? json['jenis_kelamin_meninggal']?.toString(),
      tanggalMeninggal:
          dataKematian?['tanggal']?.toString() ?? json['tanggal_meninggal']?.toString(),
      sebabMeninggal: dataKematian?['sebab']?.toString() ?? json['sebab_meninggal']?.toString(),
      configYear: json['config_year'] != null ? _parseInt(json['config_year']) : DateTime.now().year,
      keterangan: json['keterangan']?.toString(),
      active: json['active'] == 1 || json['active'] == true || json['active'] == '1',
      namaIbu: fallbackNamaIbu,
      nikIbu: nikIbu,
      namaSuami: fallbackNamaSuami,
      nikSuami: nikSuami,
      namaKelompok: namaKelompok,
      namaDusun: namaDusun,
      isPendingSync: isPendingSync,
    );
  }

  /// Payload untuk API — mengikuti skema tabel tp_pkk_catatan_ibu_anak
  /// (data ibu/kelahiran/kematian). Dipakai untuk penyimpanan offline
  /// (pending_catatan) & dikirim ulang oleh SyncService.
  Map<String, dynamic> toJson() => {
        'id': id,
        'id_warga_ibu': idWargaIbu,
        'id_warga_suami': idWargaSuami,
        'no_kk': noKk,
        'id_kelompok_dasawisma': idGroupDasawisma,
        'status_ibu': statusIbu,
        'tanggal_perkiraan_lahir': tanggalPerkiraanLahir,
        'tanggal_hamil': tanggalHamil,
        'tanggal_melahirkan': tanggalMelahirkan,
        'tanggal_nifas_selesai': tanggalNifasSelesai,
        'kelahiran_status': namaBayi != null && namaBayi!.isNotEmpty ? 'Ada' : null,
        'kelahiran_nama_bayi': namaBayi,
        'kelahiran_jenis_kelamin': jenisKelaminBayi,
        'kelahiran_tanggal': tanggalLahirBayi,
        'kelahiran_status_akte': akteKelahiran,
        'kelahiran_no_akte': noAkteKelahiran,
        'kematian_status': statusKematian,
        'kematian_nama': namaMeninggal,
        'kematian_jenis_kelamin': jenisKelaminMeninggal,
        'kematian_tanggal': tanggalMeninggal,
        'kematian_sebab': sebabMeninggal,
        'keterangan': keterangan,
        'config_year': configYear,
        'nama_ibu': namaIbu,
        'nama_suami': namaSuami,
      };

  // ============ Computed properties ============

  String get statusIbuLabel {
    if (statusIbu == null) return '-';
    switch (statusIbu!.toLowerCase()) {
      case 'hamil':
        return 'Ibu Hamil';
      case 'melahirkan':
        return 'Melahirkan';
      case 'nifas':
        return 'Masa Nifas';
      case 'meninggal':
        return 'Meninggal';
      default:
        return statusIbu!;
    }
  }

  bool get isDeath => statusKematian != null;
  bool get hasBaby => namaBayi != null && namaBayi!.isNotEmpty;

  String get jenisKelaminBayiLabel {
    if (jenisKelaminBayi == null) return '-';
    final upper = jenisKelaminBayi!.toUpperCase().trim();
    if (upper == 'L') return 'Laki-laki';
    if (upper == 'P') return 'Perempuan';
    return jenisKelaminBayi!;
  }

  String get statusKematianLabel {
    if (statusKematian == null) return '-';
    switch (statusKematian!.toLowerCase()) {
      case 'ibu':
        return 'Ibu';
      case 'bayi':
        return 'Bayi';
      case 'balita':
        return 'Balita';
      default:
        return statusKematian!;
    }
  }

  String get kelompokDisplay {
    if (namaKelompok != null && namaDusun != null) {
      return '$namaKelompok - $namaDusun';
    }
    return namaKelompok ?? '-';
  }
}
