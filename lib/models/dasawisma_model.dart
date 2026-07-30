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
  });

  factory KelompokDasawismaModel.fromJson(Map<String, dynamic> json) {
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
  final int? jumlahPus;
  final int? jumlahWus;
  final int? jumlahButa;
  final int? jumlahIbuHamil;
  final int? jumlahIbuMenyusui;
  final int? jumlahLansia;
  final String? makananPokok;
  final String? statusJamban;
  final int? jumlahGiziKurang;
  final int? jumlahGiziBuruk;
  final int? jumlahStunting;
  final int? jumlahDisabilitas;
  final String? sumberAir;
  final String? statusTempatPembuanganSampah;
  final String? statusSaluranPembuangan;
  final String? statusStickerP4k;
  final String? kriteriaRumah;
  final String? statusAktifitasUp2k;
  final String? statusAktifitasKukl;

  DasawismaKeluargaData({
    required this.noKK,
    required this.configYear,
    this.jumlahKK,
    this.jumlahBalita,
    this.jumlahPus,
    this.jumlahWus,
    this.jumlahButa,
    this.jumlahIbuHamil,
    this.jumlahIbuMenyusui,
    this.jumlahLansia,
    this.makananPokok,
    this.statusJamban,
    this.jumlahGiziKurang,
    this.jumlahGiziBuruk,
    this.jumlahStunting,
    this.jumlahDisabilitas,
    this.sumberAir,
    this.statusTempatPembuanganSampah,
    this.statusSaluranPembuangan,
    this.statusStickerP4k,
    this.kriteriaRumah,
    this.statusAktifitasUp2k,
    this.statusAktifitasKukl,
  });

  factory DasawismaKeluargaData.fromJson(Map<String, dynamic> json) {
    String? extractName(dynamic val) {
      if (val is Map) return val['nama']?.toString();
      return val?.toString();
    }

    return DasawismaKeluargaData(
      noKK: json['no_kk'] ?? '',
      configYear: _parseInt(json['config_year']),
      jumlahKK: _parseIntNullable(json['jumlah_kk']),
      jumlahBalita: _parseIntNullable(json['jumlah_balita']),
      jumlahPus: _parseIntNullable(json['jumlah_pus']),
      jumlahWus: _parseIntNullable(json['jumlah_wus']),
      jumlahButa: _parseIntNullable(json['jumlah_buta']),
      jumlahIbuHamil: _parseIntNullable(json['jumlah_ibu_hamil']),
      jumlahIbuMenyusui: _parseIntNullable(json['jumlah_ibu_menyusui']),
      jumlahLansia: _parseIntNullable(json['jumlah_lansia']),
      makananPokok: json['makanan_pokok']?.toString(),
      statusJamban: json['status_jamban']?.toString(),
      jumlahGiziKurang: _parseIntNullable(json['jumlah_gizi_kurang']),
      jumlahGiziBuruk: _parseIntNullable(json['jumlah_gizi_buruk']),
      jumlahStunting: _parseIntNullable(json['jumlah_stunting']),
      jumlahDisabilitas: _parseIntNullable(json['jumlah_disabilitas']),
      sumberAir: extractName(json['sumber_air']),
      statusTempatPembuanganSampah: json['status_tempat_pembuangan_sampah']?.toString(),
      statusSaluranPembuangan: json['status_saluran_pembuangan']?.toString(),
      statusStickerP4k: json['status_sticker_p4k']?.toString(),
      kriteriaRumah: json['kriteria_rumah']?.toString(),
      statusAktifitasUp2k: json['status_aktifitas_up2k']?.toString(),
      statusAktifitasKukl: json['status_aktifitas_kukl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'no_kk': noKK,
        'config_year': configYear,
        'jumlah_kk': jumlahKK,
        'jumlah_balita': jumlahBalita,
        'jumlah_pus': jumlahPus,
        'jumlah_wus': jumlahWus,
        'jumlah_buta': jumlahButa,
        'jumlah_ibu_hamil': jumlahIbuHamil,
        'jumlah_ibu_menyusui': jumlahIbuMenyusui,
        'jumlah_lansia': jumlahLansia,
        'makanan_pokok': makananPokok,
        'status_jamban': statusJamban,
        'jumlah_gizi_kurang': jumlahGiziKurang,
        'jumlah_gizi_buruk': jumlahGiziBuruk,
        'jumlah_stunting': jumlahStunting,
        'jumlah_disabilitas': jumlahDisabilitas,
        'id_sumber_air': null,
        'status_tempat_pembuangan_sampah': statusTempatPembuanganSampah,
        'status_saluran_pembuangan': statusSaluranPembuangan,
        'status_sticker_p4k': statusStickerP4k,
        'kriteria_rumah': kriteriaRumah,
        'status_aktifitas_up2k': statusAktifitasUp2k,
        'status_aktifitas_kukl': statusAktifitasKukl,
      };
}
