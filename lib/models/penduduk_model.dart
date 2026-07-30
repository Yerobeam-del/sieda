class PendudukModel {
  final String nik;
  final String nama;
  final String? tempatLahir;
  final String? tanggalLahir;
  final String? jenisKelamin;
  final String? alamat;
  final String? noHp;
  final String? agama;
  final String? pendidikan;
  final String? pekerjaan;
  final String? statusPerkawinan;
  final String? peranKeluarga;
  final String? statusKeluarga;
  final bool active;

  PendudukModel({
    required this.nik,
    required this.nama,
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
    this.active = true,
  });

  factory PendudukModel.fromJson(Map<String, dynamic> json) {
    return PendudukModel(
      nik: json['nik'] ?? '',
      nama: json['nama'] ?? '',
      tempatLahir: json['tempat_lahir'],
      tanggalLahir: json['tanggal_lahir'],
      jenisKelamin: json['jenis_kelamin'],
      alamat: json['alamat'],
      noHp: json['no_hp'],
      agama: json['agama'] is Map ? json['agama']?['nama'] : json['agama']?.toString(),
      pendidikan: json['pendidikan'] is Map
          ? json['pendidikan']?['nama']
          : json['pendidikan']?.toString(),
      pekerjaan: json['pekerjaan'] is Map
          ? json['pekerjaan']?['nama']
          : json['pekerjaan']?.toString(),
      statusPerkawinan: json['status_perkawinan'],
      peranKeluarga: json['peran_keluarga'],
      statusKeluarga: json['status_keluarga'],
      active: json['active'] ?? true,
    );
  }

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
}
