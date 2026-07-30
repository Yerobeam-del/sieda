/// Helper: parse dynamic value ke int dengan aman.
///
/// MySQL/PHP sering return angka sebagai string ("0" bukan 0)
/// di JSON. Dart strong-typed, jadi perlu konversi eksplisit.
int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

class DashboardModel {
  final int configYear;
  final Ringkasan ringkasan;
  final List<PerDusun> perDusun;
  final List<Kesehatan> kesehatan;
  final CatatanSummary catatanSummary;

  DashboardModel({
    required this.configYear,
    required this.ringkasan,
    this.perDusun = const [],
    this.kesehatan = const [],
    this.catatanSummary = const CatatanSummary(),
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      configYear: _parseInt(json['config_year']),
      ringkasan: Ringkasan.fromJson(json['ringkasan'] ?? {}),
      perDusun: (json['per_dusun'] as List<dynamic>?)
              ?.map((e) => PerDusun.fromJson(e))
              .toList() ??
          [],
      kesehatan: (json['kesehatan'] as List<dynamic>?)
              ?.map((e) => Kesehatan.fromJson(e))
              .toList() ??
          [],
      catatanSummary: CatatanSummary.fromJson(json['catatan_summary'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class Ringkasan {
  final int totalKeluarga;
  final int totalPenduduk;
  final int totalLakiLaki;
  final int totalPerempuan;

  Ringkasan({
    required this.totalKeluarga,
    required this.totalPenduduk,
    required this.totalLakiLaki,
    required this.totalPerempuan,
  });

  factory Ringkasan.fromJson(Map<String, dynamic> json) {
    return Ringkasan(
      totalKeluarga: _parseInt(json['total_keluarga']),
      totalPenduduk: _parseInt(json['total_penduduk']),
      totalLakiLaki: _parseInt(json['total_laki_laki']),
      totalPerempuan: _parseInt(json['total_perempuan']),
    );
  }

  int get totalJiwa => totalLakiLaki + totalPerempuan;
}

class PerDusun {
  final int id;
  final String dusun;
  final int totalKeluarga;
  final int totalPenduduk;

  PerDusun({
    required this.id,
    required this.dusun,
    required this.totalKeluarga,
    required this.totalPenduduk,
  });

  factory PerDusun.fromJson(Map<String, dynamic> json) {
    return PerDusun(
      id: _parseInt(json['id']),
      dusun: json['dusun'] ?? '',
      totalKeluarga: _parseInt(json['total_keluarga']),
      totalPenduduk: _parseInt(json['total_penduduk']),
    );
  }
}

class Kesehatan {
  final String dusun;
  final int totalBalita;
  final int ibuHamil;
  final int ibuMenyusui;
  final int stunting;
  final int lansia;

  Kesehatan({
    required this.dusun,
    required this.totalBalita,
    required this.ibuHamil,
    required this.ibuMenyusui,
    required this.stunting,
    required this.lansia,
  });

  factory Kesehatan.fromJson(Map<String, dynamic> json) {
    return Kesehatan(
      dusun: json['dusun'] ?? '',
      totalBalita: _parseInt(json['total_balita']),
      ibuHamil: _parseInt(json['ibu_hamil']),
      ibuMenyusui: _parseInt(json['ibu_menyusui']),
      stunting: _parseInt(json['stunting']),
      lansia: _parseInt(json['lansia']),
    );
  }
}

class DetailDusun {
  final Map<String, dynamic> dusun;
  final List<DetailKelompok> detail;

  DetailDusun({required this.dusun, required this.detail});

  factory DetailDusun.fromJson(Map<String, dynamic> json) {
    return DetailDusun(
      dusun: json['dusun'] ?? {},
      detail: (json['detail'] as List<dynamic>?)
              ?.map((e) => DetailKelompok.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class CatatanSummary {
  final int hamilBulanIni;
  final int melahirkanBulanIni;
  final int kematianBayiBalita;
  final int totalCatatan;

  const CatatanSummary({
    this.hamilBulanIni = 0,
    this.melahirkanBulanIni = 0,
    this.kematianBayiBalita = 0,
    this.totalCatatan = 0,
  });

  factory CatatanSummary.fromJson(Map<String, dynamic> json) {
    return CatatanSummary(
      hamilBulanIni: _parseInt(json['hamil_bulan_ini']),
      melahirkanBulanIni: _parseInt(json['melahirkan_bulan_ini']),
      kematianBayiBalita: _parseInt(json['kematian_bayi_balita']),
      totalCatatan: _parseInt(json['total_catatan']),
    );
  }
}

class DetailKelompok {
  final int id;
  final String kelompok;
  final int totalKeluarga;
  final int totalPenduduk;
  final int lakiLaki;
  final int perempuan;

  DetailKelompok({
    required this.id,
    required this.kelompok,
    required this.totalKeluarga,
    required this.totalPenduduk,
    required this.lakiLaki,
    required this.perempuan,
  });

  factory DetailKelompok.fromJson(Map<String, dynamic> json) {
    return DetailKelompok(
      id: _parseInt(json['id']),
      kelompok: json['kelompok'] ?? '',
      totalKeluarga: _parseInt(json['total_keluarga']),
      totalPenduduk: _parseInt(json['total_penduduk']),
      lakiLaki: _parseInt(json['laki_laki']),
      perempuan: _parseInt(json['perempuan']),
    );
  }
}
