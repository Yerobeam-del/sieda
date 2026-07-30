class CatatanKelahiranKematianModel {
  final int id;
  final String? idWargaIbu;
  final String? idWargaSuami;
  final String? noKk;
  final int? idGroupDasawisma;
  final String? statusIbu;
  final String? tanggalHamil;
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

  CatatanKelahiranKematianModel({
    required this.id,
    this.idWargaIbu,
    this.idWargaSuami,
    this.noKk,
    this.idGroupDasawisma,
    this.statusIbu,
    this.tanggalHamil,
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
  });

  factory CatatanKelahiranKematianModel.fromJson(Map<String, dynamic> json) {
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

    return CatatanKelahiranKematianModel(
      id: json['id'] ?? 0,
      idWargaIbu: json['id_warga_ibu']?.toString(),
      idWargaSuami: json['id_warga_suami']?.toString(),
      noKk: json['no_kk']?.toString(),
      idGroupDasawisma: json['id_group_dasawisma'] is int
          ? json['id_group_dasawisma']
          : int.tryParse(json['id_group_dasawisma']?.toString() ?? ''),
      statusIbu: json['status_ibu']?.toString(),
      tanggalHamil: json['tanggal_hamil']?.toString(),
      tanggalMelahirkan: json['tanggal_melahirkan']?.toString(),
      tanggalNifasSelesai: json['tanggal_nifas_selesai']?.toString(),
      namaBayi: json['nama_bayi']?.toString(),
      jenisKelaminBayi: json['jenis_kelamin_bayi']?.toString(),
      tanggalLahirBayi: json['tanggal_lahir_bayi']?.toString(),
      akteKelahiran: json['akte_kelahiran']?.toString(),
      noAkteKelahiran: json['no_akte_kelahiran']?.toString(),
      statusKematian: json['status_kematian']?.toString(),
      namaMeninggal: json['nama_meninggal']?.toString(),
      jenisKelaminMeninggal: json['jenis_kelamin_meninggal']?.toString(),
      tanggalMeninggal: json['tanggal_meninggal']?.toString(),
      sebabMeninggal: json['sebab_meninggal']?.toString(),
      configYear: json['config_year'] ?? DateTime.now().year,
      keterangan: json['keterangan']?.toString(),
      active: json['active'] == 1 || json['active'] == true,
      namaIbu: fallbackNamaIbu,
      nikIbu: nikIbu,
      namaSuami: fallbackNamaSuami,
      nikSuami: nikSuami,
      namaKelompok: namaKelompok,
      namaDusun: namaDusun,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'id_warga_ibu': idWargaIbu,
        'id_warga_suami': idWargaSuami,
        'no_kk': noKk,
        'id_group_dasawisma': idGroupDasawisma,
        'status_ibu': statusIbu,
        'tanggal_hamil': tanggalHamil,
        'tanggal_melahirkan': tanggalMelahirkan,
        'tanggal_nifas_selesai': tanggalNifasSelesai,
        'nama_bayi': namaBayi,
        'jenis_kelamin_bayi': jenisKelaminBayi,
        'tanggal_lahir_bayi': tanggalLahirBayi,
        'akte_kelahiran': akteKelahiran,
        'no_akte_kelahiran': noAkteKelahiran,
        'status_kematian': statusKematian,
        'nama_meninggal': namaMeninggal,
        'jenis_kelamin_meninggal': jenisKelaminMeninggal,
        'tanggal_meninggal': tanggalMeninggal,
        'sebab_meninggal': sebabMeninggal,
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
