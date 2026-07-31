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
  if (value is String) return int.tryParse(value);
  return null;
}

class KelompokDasawismaModel {
  final int id;
  final String nama;
  final String? namaKader;
  final int? idDusun;
  final String? dusun;
  final int configYear;
  final int? totalKeluarga;
  final int? totalAnggota;
  final bool active;

  /// true bila record ini berasal dari antrian offline (belum tersinkron
  /// ke server) — dipakai UI untuk menampilkan badge "Menunggu sinkron".
  final bool isPendingSync;

  KelompokDasawismaModel({
    required this.id,
    required this.nama,
    this.namaKader,
    this.idDusun,
    this.dusun,
    required this.configYear,
    this.totalKeluarga,
    this.totalAnggota,
    this.active = true,
    this.isPendingSync = false,
  });

  factory KelompokDasawismaModel.fromJson(
    Map<String, dynamic> json, {
    bool isPendingSync = false,
  }) {
    bool parseActive(dynamic val) => val == 1 || val == true || val == '1';

    // Parse nested dusun
    String? getDusun(dynamic val) {
      if (val is Map) return val['nama']?.toString();
      return val?.toString();
    }

    String? getKader(dynamic val) {
      if (val is Map) return val['nama']?.toString();
      return val?.toString();
    }

    return KelompokDasawismaModel(
      id: _parseInt(json['id']),
      nama: json['nama'] ?? '',
      namaKader: getKader(json['kader']),
      idDusun: _parseIntNullable(json['id_dusun']),
      dusun: getDusun(json['dusun']),
      configYear: _parseInt(json['config_year']),
      totalKeluarga: _parseIntNullable(json['total_keluarga']),
      totalAnggota: _parseIntNullable(json['total_anggota']),
      active: parseActive(json['active']),
      isPendingSync: isPendingSync,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'id_dusun': idDusun,
        'kader': namaKader,
        'config_year': configYear,
      };
}

class RingkasanPerDusun {
  final int id;
  final String dusun;
  final int totalKelompok;
  final int totalKeluarga;
  final int totalPenduduk;

  RingkasanPerDusun({
    required this.id,
    required this.dusun,
    required this.totalKelompok,
    required this.totalKeluarga,
    required this.totalPenduduk,
  });

  factory RingkasanPerDusun.fromJson(Map<String, dynamic> json) {
    // Support both snake_case and camelCase keys
    return RingkasanPerDusun(
      id: _parseInt(json['dusun_id'] ?? json['id']),
      dusun: json['dusun_nama'] ?? json['dusun'] ?? '',
      totalKelompok: _parseInt(json['total_kelompok']),
      totalKeluarga: _parseInt(json['total_keluarga']),
      totalPenduduk: _parseInt(json['total_penduduk']),
    );
  }
}

class DasawismaKesehatanModel {
  final int? id;
  final String? kelompok;
  final String? dusun;
  final int totalBalita;
  final int ibuHamil;
  final int ibuMenyusui;
  final int stunting;
  final int lansia;
  final int totalKeluarga;

  /// true bila record ini berasal dari antrian offline (belum tersinkron
  /// ke server) — dipakai UI untuk menampilkan badge "Menunggu sinkron".
  final bool isPendingSync;

  DasawismaKesehatanModel({
    this.id,
    this.kelompok,
    this.dusun,
    this.totalBalita = 0,
    this.ibuHamil = 0,
    this.ibuMenyusui = 0,
    this.stunting = 0,
    this.lansia = 0,
    this.totalKeluarga = 0,
    this.isPendingSync = false,
  });

  factory DasawismaKesehatanModel.fromJson(Map<String, dynamic> json) {
    return DasawismaKesehatanModel(
      id: _parseIntNullable(json['id']),
      kelompok: json['kelompok']?.toString(),
      dusun: json['dusun']?.toString(),
      totalBalita: _parseInt(json['total_balita']),
      ibuHamil: _parseInt(json['ibu_hamil']),
      ibuMenyusui: _parseInt(json['ibu_menyusui']),
      stunting: _parseInt(json['stunting']),
      lansia: _parseInt(json['lansia']),
      totalKeluarga: _parseInt(json['total_keluarga']),
    );
  }
}

class DasawismaKeluargaData {
  final String noKK;
  final int configYear;
  final int? jumlahKK;
  final int? jumlahBalita;
  final int? jumlahBalitaLakiLaki;
  final int? jumlahBalitaPerempuan;
  final int? jumlahPus;
  final int? jumlahWus;
  final int? jumlahButa;
  final int? jumlahIbuHamil;
  final int? jumlahIbuMenyusui;
  final int? jumlahLansia;
  final String? makananPokok;
  final int? idJenisMakananPokok;
  final String? statusJamban;
  final int? jumlahJamban;
  final int? idSumberAir;
  final String? sumberAir;
  final int? jumlahGiziKurang;
  final int? jumlahGiziBuruk;
  final int? jumlahStunting;
  final int? jumlahDisabilitas;
  final String? statusTempatPembuanganSampah;
  final String? statusSaluranPembuangan;
  final String? statusStickerP4k;
  final String? kriteriaRumah;
  final String? statusAktifitasUp2k;
  final int? idJenisUsahaUp2k;
  final String? statusAktifitasKukl;

  /// true bila record ini berasal dari antrian offline (belum tersinkron
  /// ke server) — dipakai UI untuk menampilkan badge "Menunggu sinkron".
  final bool isPendingSync;

  DasawismaKeluargaData({
    required this.noKK,
    required this.configYear,
    this.jumlahKK,
    this.jumlahBalita,
    this.jumlahBalitaLakiLaki,
    this.jumlahBalitaPerempuan,
    this.jumlahPus,
    this.jumlahWus,
    this.jumlahButa,
    this.jumlahIbuHamil,
    this.jumlahIbuMenyusui,
    this.jumlahLansia,
    this.makananPokok,
    this.idJenisMakananPokok,
    this.statusJamban,
    this.jumlahJamban,
    this.idSumberAir,
    this.sumberAir,
    this.jumlahGiziKurang,
    this.jumlahGiziBuruk,
    this.jumlahStunting,
    this.jumlahDisabilitas,
    this.statusTempatPembuanganSampah,
    this.statusSaluranPembuangan,
    this.statusStickerP4k,
    this.kriteriaRumah,
    this.statusAktifitasUp2k,
    this.idJenisUsahaUp2k,
    this.statusAktifitasKukl,
    this.isPendingSync = false,
  });

  factory DasawismaKeluargaData.fromJson(
    Map<String, dynamic> json, {
    bool isPendingSync = false,
  }) {
    String? extractName(dynamic val) {
      if (val is Map) return val['nama']?.toString();
      return val?.toString();
    }

    return DasawismaKeluargaData(
      noKK: json['no_kk'] ?? '',
      configYear: _parseInt(json['config_year']),
      jumlahKK: _parseIntNullable(json['jumlah_kk']),
      jumlahBalita: _parseIntNullable(json['jumlah_balita']),
      jumlahBalitaLakiLaki: _parseIntNullable(json['jumlah_balita_laki_laki']),
      jumlahBalitaPerempuan: _parseIntNullable(json['jumlah_balita_perempuan']),
      jumlahPus: _parseIntNullable(json['jumlah_pus']),
      jumlahWus: _parseIntNullable(json['jumlah_wus']),
      jumlahButa: _parseIntNullable(json['jumlah_buta']),
      jumlahIbuHamil: _parseIntNullable(json['jumlah_ibu_hamil']),
      jumlahIbuMenyusui: _parseIntNullable(json['jumlah_ibu_menyusui']),
      jumlahLansia: _parseIntNullable(json['jumlah_lansia']),
      makananPokok: json['makanan_pokok']?.toString(),
      idJenisMakananPokok: _parseIntNullable(json['id_jenis_makanan_pokok']),
      statusJamban: json['status_jamban']?.toString(),
      jumlahJamban: _parseIntNullable(json['jumlah_jamban']),
      idSumberAir: _parseIntNullable(json['id_sumber_air']),
      sumberAir: extractName(json['sumber_air']),
      jumlahGiziKurang: _parseIntNullable(json['jumlah_gizi_kurang']),
      jumlahGiziBuruk: _parseIntNullable(json['jumlah_gizi_buruk']),
      jumlahStunting: _parseIntNullable(json['jumlah_stunting']),
      jumlahDisabilitas: _parseIntNullable(json['jumlah_disabilitas']),
      statusTempatPembuanganSampah: json['status_tempat_pembuangan_sampah']?.toString(),
      statusSaluranPembuangan: json['status_saluran_pembuangan']?.toString(),
      statusStickerP4k: json['status_sticker_p4k']?.toString(),
      kriteriaRumah: json['kriteria_rumah']?.toString(),
      statusAktifitasUp2k: json['status_aktifitas_up2k']?.toString(),
      idJenisUsahaUp2k: _parseIntNullable(json['id_jenis_usaha_up2k']),
      statusAktifitasKukl: json['status_aktifitas_kukl']?.toString(),
      isPendingSync: isPendingSync,
    );
  }

  Map<String, dynamic> toJson() => {
        'no_kk': noKK,
        'config_year': configYear,
        'jumlah_kk': jumlahKK,
        'jumlah_balita': jumlahBalita,
        'jumlah_balita_laki_laki': jumlahBalitaLakiLaki,
        'jumlah_balita_perempuan': jumlahBalitaPerempuan,
        'jumlah_pus': jumlahPus,
        'jumlah_wus': jumlahWus,
        'jumlah_buta': jumlahButa,
        'jumlah_ibu_hamil': jumlahIbuHamil,
        'jumlah_ibu_menyusui': jumlahIbuMenyusui,
        'jumlah_lansia': jumlahLansia,
        'makanan_pokok': makananPokok,
        'id_jenis_makanan_pokok': idJenisMakananPokok,
        'status_jamban': statusJamban,
        'jumlah_jamban': jumlahJamban,
        'id_sumber_air': idSumberAir,
        'jumlah_gizi_kurang': jumlahGiziKurang,
        'jumlah_gizi_buruk': jumlahGiziBuruk,
        'jumlah_stunting': jumlahStunting,
        'jumlah_disabilitas': jumlahDisabilitas,
        'status_tempat_pembuangan_sampah': statusTempatPembuanganSampah,
        'status_saluran_pembuangan': statusSaluranPembuangan,
        'status_sticker_p4k': statusStickerP4k,
        'kriteria_rumah': kriteriaRumah,
        'status_aktifitas_up2k': statusAktifitasUp2k,
        'id_jenis_usaha_up2k': idJenisUsahaUp2k,
        'status_aktifitas_kukl': statusAktifitasKukl,
      };
}
