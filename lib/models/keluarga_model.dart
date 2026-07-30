import 'penduduk_model.dart';

class KeluargaModel {
  final String noKk;
  final String? idKepalaKeluarga;
  final String? idKelompokDasawisma;
  final int configYear;
  final bool active;
  final PendudukModel? kepalaKeluarga;
  final KelompokDasawismaMini? kelompokDasawisma;
  final DasawismaKeluargaData? dasawismaKeluarga;
  final List<PendudukModel> anggota;

  KeluargaModel({
    required this.noKk,
    this.idKepalaKeluarga,
    this.idKelompokDasawisma,
    required this.configYear,
    this.active = true,
    this.kepalaKeluarga,
    this.kelompokDasawisma,
    this.dasawismaKeluarga,
    this.anggota = const [],
  });

  factory KeluargaModel.fromJson(Map<String, dynamic> json) {
    return KeluargaModel(
      noKk: json['no_kk'] ?? '',
      idKepalaKeluarga: json['id_kepala_keluarga'],
      idKelompokDasawisma: json['id_kelompok_dasawisma'],
      configYear: json['config_year'] ?? 0,
      active: json['active'] ?? true,
      kepalaKeluarga: json['kepala_keluarga'] != null
          ? PendudukModel.fromJson(json['kepala_keluarga'])
          : null,
      kelompokDasawisma: json['kelompok_dasawisma'] != null
          ? KelompokDasawismaMini.fromJson(json['kelompok_dasawisma'])
          : null,
      dasawismaKeluarga: json['dasawisma_keluarga'] != null
          ? DasawismaKeluargaData.fromJson(json['dasawisma_keluarga'])
          : null,
      anggota: json['anggota'] != null
          ? (json['anggota'] as List<dynamic>)
              .map((e) => PendudukModel.fromJson(e))
              .toList()
          : [],
    );
  }
}

class KelompokDasawismaMini {
  final int id;
  final String nama;
  final String? dusun;

  KelompokDasawismaMini({
    required this.id,
    required this.nama,
    this.dusun,
  });

  factory KelompokDasawismaMini.fromJson(Map<String, dynamic> json) {
    return KelompokDasawismaMini(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      dusun: json['dusun'] is Map
          ? json['dusun']?['nama']
          : json['dusun']?.toString(),
    );
  }
}

class DasawismaKeluargaData {
  final int? jumlahBalita;
  final int? jumlahIbuHamil;
  final int? jumlahIbuMenyusui;
  final int? jumlahStunting;
  final int? jumlahLansia;

  DasawismaKeluargaData({
    this.jumlahBalita,
    this.jumlahIbuHamil,
    this.jumlahIbuMenyusui,
    this.jumlahStunting,
    this.jumlahLansia,
  });

  factory DasawismaKeluargaData.fromJson(Map<String, dynamic> json) {
    return DasawismaKeluargaData(
      jumlahBalita: json['jumlah_balita'],
      jumlahIbuHamil: json['jumlah_ibu_hamil'],
      jumlahIbuMenyusui: json['jumlah_ibu_menyusui'],
      jumlahStunting: json['jumlah_stunting'],
      jumlahLansia: json['jumlah_lansia'],
    );
  }
}
