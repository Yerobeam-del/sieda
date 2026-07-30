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
      configYear: json['config_year'] ?? 0,
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
      totalKeluarga: json['total_keluarga'] ?? 0,
      totalPenduduk: json['total_penduduk'] ?? 0,
      totalLakiLaki: json['total_laki_laki'] ?? 0,
      totalPerempuan: json['total_perempuan'] ?? 0,
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
      id: json['id'] ?? 0,
      dusun: json['dusun'] ?? '',
      totalKeluarga: json['total_keluarga'] ?? 0,
      totalPenduduk: json['total_penduduk'] ?? 0,
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
      totalBalita: json['total_balita'] ?? 0,
      ibuHamil: json['ibu_hamil'] ?? 0,
      ibuMenyusui: json['ibu_menyusui'] ?? 0,
      stunting: json['stunting'] ?? 0,
      lansia: json['lansia'] ?? 0,
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
      hamilBulanIni: json['hamil_bulan_ini'] ?? 0,
      melahirkanBulanIni: json['melahirkan_bulan_ini'] ?? 0,
      kematianBayiBalita: json['kematian_bayi_balita'] ?? 0,
      totalCatatan: json['total_catatan'] ?? 0,
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
      id: json['id'] ?? 0,
      kelompok: json['kelompok'] ?? '',
      totalKeluarga: json['total_keluarga'] ?? 0,
      totalPenduduk: json['total_penduduk'] ?? 0,
      lakiLaki: json['laki_laki'] ?? 0,
      perempuan: json['perempuan'] ?? 0,
    );
  }
}
