import 'penduduk_model.dart';

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

  /// true bila record ini berasal dari antrian offline (belum tersinkron
  /// ke server) — dipakai UI untuk menampilkan badge "Menunggu sinkron".
  final bool isPendingSync;

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
    this.isPendingSync = false,
  });

  factory KeluargaModel.fromJson(Map<String, dynamic> json, {bool isPendingSync = false}) {
    bool parseActive(dynamic val) {
      return val == 1 || val == true || val == '1';
    }

    PendudukModel? parseKepalaKeluarga(dynamic val) {
      if (val is Map<String, dynamic>) {
        return PendudukModel.fromJson(val);
      }
      return null;
    }

    KelompokDasawismaMini? parseKelompok(dynamic val) {
      if (val is Map<String, dynamic>) {
        return KelompokDasawismaMini.fromJson(val);
      }
      return null;
    }

    DasawismaKeluargaData? parseDasawisma(dynamic val) {
      if (val is Map<String, dynamic>) {
        return DasawismaKeluargaData.fromJson(val);
      }
      return null;
    }

    return KeluargaModel(
      noKk: json['no_kk'] ?? '',
      idKepalaKeluarga: json['id_kepala_keluarga']?.toString(),
      idKelompokDasawisma: json['id_kelompok_dasawisma']?.toString(),
      configYear: _parseInt(json['config_year']),
      active: parseActive(json['active']),
      kepalaKeluarga: parseKepalaKeluarga(json['kepala_keluarga']),
      kelompokDasawisma: parseKelompok(json['kelompok_dasawisma']),
      dasawismaKeluarga: parseDasawisma(json['dasawisma_keluarga']),
      anggota: _parseAnggota(json['anggota']),
      isPendingSync: isPendingSync,
    );
  }

  static List<PendudukModel> _parseAnggota(dynamic data) {
    if (data is List) {
      return data.map((e) {
        if (e is Map<String, dynamic>) return PendudukModel.fromJson(e);
        return PendudukModel.fromJson(e as Map<String, dynamic>);
      }).toList();
    }
    return [];
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
    String? getDusun(dynamic val) {
      if (val is Map) {
        return val['nama']?.toString();
      }
      return val?.toString();
    }

    return KelompokDasawismaMini(
      id: _parseInt(json['id']),
      nama: json['nama'] ?? '',
      dusun: getDusun(json['dusun']),
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
      jumlahBalita: _parseIntNullable(json['jumlah_balita']),
      jumlahIbuHamil: _parseIntNullable(json['jumlah_ibu_hamil']),
      jumlahIbuMenyusui: _parseIntNullable(json['jumlah_ibu_menyusui']),
      jumlahStunting: _parseIntNullable(json['jumlah_stunting']),
      jumlahLansia: _parseIntNullable(json['jumlah_lansia']),
    );
  }
}
