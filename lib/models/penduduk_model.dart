class PendudukModel {
  // Identitas dasar
  final String nik;
  final String nama;
  final String? noRegistrasi;
  final String? tempatLahir;
  final String? tanggalLahir;
  final String? jenisKelamin;
  final String? alamat;
  final String? noHp;

  // Referensi (relasi — disimpan sebagai String nama untuk display)
  final String? agama;
  final String? pendidikan;
  final String? pekerjaan;
  final String? statusPerkawinan;
  final String? peranKeluarga;
  final String? statusKeluarga;

  // Status PKK
  final String? statusAkseptor;
  final String? jenisAkseptor;
  final String? statusPosyandu;
  final String? frekuensiPosyandu;
  final String? satuanFrekuensiVolume;
  final String? statusPbkb;
  final String? statusTabungan;
  final String? statusKelompokBelajar;
  final String? jenisKelompokBelajar;
  final String? statusPaud;
  final String? statusKegiatanKoperasi;
  final String? jenisKoperasi;
  final String? statusKebutuhanKhusus;
  final String? kebutuhanKhusus;

  final bool active;

  /// true bila record ini berasal dari antrian offline (belum tersinkron
  /// ke server) — dipakai UI untuk menampilkan badge "Menunggu sinkron".
  final bool isPendingSync;

  PendudukModel({
    required this.nik,
    required this.nama,
    this.noRegistrasi,
    this.tempatLahir,
    this.tanggalLahir,
    this.jenisKelamin,
    this.alamat,
    this.noHp,
    this.agama,
    this.pendidikan,
    this.pekerjaan,
    this.statusPerkawinan,
    this.peranKeluarga,
    this.statusKeluarga,
    this.statusAkseptor,
    this.jenisAkseptor,
    this.statusPosyandu,
    this.frekuensiPosyandu,
    this.satuanFrekuensiVolume,
    this.statusPbkb,
    this.statusTabungan,
    this.statusKelompokBelajar,
    this.jenisKelompokBelajar,
    this.statusPaud,
    this.statusKegiatanKoperasi,
    this.jenisKoperasi,
    this.statusKebutuhanKhusus,
    this.kebutuhanKhusus,
    this.active = true,
    this.isPendingSync = false,
  });

  factory PendudukModel.fromJson(Map<String, dynamic> json, {bool isPendingSync = false}) {
    String? extractName(dynamic val) {
      if (val is Map) {
        return val['nama']?.toString();
      }
      return val?.toString();
    }

    bool parseActive(dynamic val) => val == 1 || val == true || val == '1';

    return PendudukModel(
      nik: json['nik'] ?? '',
      nama: json['nama'] ?? '',
      noRegistrasi: json['no_registrasi']?.toString(),
      tempatLahir: json['tempat_lahir']?.toString(),
      tanggalLahir: json['tanggal_lahir']?.toString(),
      jenisKelamin: json['jenis_kelamin']?.toString(),
      alamat: json['alamat']?.toString(),
      noHp: json['no_hp']?.toString(),
      agama: extractName(json['agama']),
      pendidikan: extractName(json['pendidikan']),
      pekerjaan: extractName(json['pekerjaan']),
      statusPerkawinan: extractName(json['status_perkawinan']),
      peranKeluarga: extractName(json['peran_keluarga']),
      statusKeluarga: extractName(json['status_keluarga']),
      statusAkseptor: json['status_akseptor']?.toString(),
      jenisAkseptor: extractName(json['jenis_akseptor']),
      statusPosyandu: json['status_posyandu']?.toString(),
      frekuensiPosyandu: json['frekuensi_posyandu']?.toString(),
      satuanFrekuensiVolume: json['satuan_frekuensi_volume']?.toString(),
      statusPbkb: json['status_pbkb']?.toString(),
      statusTabungan: json['status_tabungan']?.toString(),
      statusKelompokBelajar: json['status_kelompok_belajar']?.toString(),
      jenisKelompokBelajar: extractName(json['jenis_kelompok_belajar']),
      statusPaud: json['status_paud']?.toString(),
      statusKegiatanKoperasi: json['status_kegiatan_koperasi']?.toString(),
      jenisKoperasi: extractName(json['jenis_koperasi']),
      statusKebutuhanKhusus: json['status_kebutuhan_khusus']?.toString(),
      kebutuhanKhusus: extractName(json['kebutuhan_khusus']),
      active: parseActive(json['active']),
      isPendingSync: isPendingSync,
    );
  }

  // ============ Computed properties ============

  /// Salinan model dengan nilai field tertentu diganti. Saat ini dipakai
  /// untuk menandai item sebagai pending sinkron (isPendingSync).
  PendudukModel copyWith({bool? isPendingSync}) => PendudukModel(
        nik: nik,
        nama: nama,
        noRegistrasi: noRegistrasi,
        tempatLahir: tempatLahir,
        tanggalLahir: tanggalLahir,
        jenisKelamin: jenisKelamin,
        alamat: alamat,
        noHp: noHp,
        agama: agama,
        pendidikan: pendidikan,
        pekerjaan: pekerjaan,
        statusPerkawinan: statusPerkawinan,
        peranKeluarga: peranKeluarga,
        statusKeluarga: statusKeluarga,
        statusAkseptor: statusAkseptor,
        jenisAkseptor: jenisAkseptor,
        statusPosyandu: statusPosyandu,
        frekuensiPosyandu: frekuensiPosyandu,
        satuanFrekuensiVolume: satuanFrekuensiVolume,
        statusPbkb: statusPbkb,
        statusTabungan: statusTabungan,
        statusKelompokBelajar: statusKelompokBelajar,
        jenisKelompokBelajar: jenisKelompokBelajar,
        statusPaud: statusPaud,
        statusKegiatanKoperasi: statusKegiatanKoperasi,
        jenisKoperasi: jenisKoperasi,
        statusKebutuhanKhusus: statusKebutuhanKhusus,
        kebutuhanKhusus: kebutuhanKhusus,
        active: active,
        isPendingSync: isPendingSync ?? this.isPendingSync,
      );

  String get genderLabel {
    if (jenisKelamin == null) return '-';
    final upper = jenisKelamin!.toUpperCase().trim();
    if (upper == 'L' || upper == 'LAKI-LAKI') return 'Laki-laki';
    if (upper == 'P' || upper == 'PEREMPUAN') return 'Perempuan';
    return jenisKelamin!;
  }

  String get usiaLabel {
    if (tanggalLahir == null) return '-';
    try {
      final birth = DateTime.parse(tanggalLahir!);
      final now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return '$age tahun';
    } catch (_) {
      return '-';
    }
  }

  String get formattedTtl {
    final ttl = tempatLahir ?? '';
    final tgl = tanggalLahir ?? '-';
    return ttl.isNotEmpty ? '$ttl, $tgl' : tgl;
  }

  String get formattedStatusKeluarga {
    final peran = peranKeluarga ?? '-';
    final status = statusKeluarga ?? '-';
    return '$peran / $status';
  }


}
