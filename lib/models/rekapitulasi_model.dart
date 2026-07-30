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

class RekapitulasiModel {
  final int id;
  final int configYear;
  final String? dusun;
  final String? kegiatan;
  final String? volumeKegiatan;
  final String? metode;
  final String? jumlahSasaran;
  final String? keterangan;

  RekapitulasiModel({
    required this.id,
    required this.configYear,
    this.dusun,
    this.kegiatan,
    this.volumeKegiatan,
    this.metode,
    this.jumlahSasaran,
    this.keterangan,
  });

  factory RekapitulasiModel.fromJson(Map<String, dynamic> json) {
    return RekapitulasiModel(
      id: _parseInt(json['id']),
      configYear: _parseInt(json['config_year']),
      dusun: json['dusun']?.toString(),
      kegiatan: json['kegiatan']?.toString(),
      volumeKegiatan: json['volume_kegiatan']?.toString(),
      metode: json['metode']?.toString(),
      jumlahSasaran: json['jumlah_sasaran']?.toString(),
      keterangan: json['keterangan']?.toString(),
    );
  }
}

class RekapitulasiPokja {
  final List<RekapitulasiModel> data;
  final String label;

  RekapitulasiPokja({required this.data, required this.label});
}

class DataUmumPKK {
  final int id;
  final int configYear;
  final String? dusun;
  final String? jumlahKeluarga;
  final String? jumlahPenduduk;
  final String? jumlahKader;
  final String? keterangan;

  DataUmumPKK({
    required this.id,
    required this.configYear,
    this.dusun,
    this.jumlahKeluarga,
    this.jumlahPenduduk,
    this.jumlahKader,
    this.keterangan,
  });

  factory DataUmumPKK.fromJson(Map<String, dynamic> json) {
    return DataUmumPKK(
      id: _parseInt(json['id']),
      configYear: _parseInt(json['config_year']),
      dusun: json['dusun']?.toString(),
      jumlahKeluarga: json['jumlah_keluarga']?.toString(),
      jumlahPenduduk: json['jumlah_penduduk']?.toString(),
      jumlahKader: json['jumlah_kader']?.toString(),
      keterangan: json['keterangan']?.toString(),
    );
  }
}

class CatatanKelahiranKematianModel {
  final int id;
  final String? idWargaIbu;
  final String? namaIbu;
  final String? idWargaSuami;
  final String? namaSuami;
  final String? noKk;
  final int? idGroupDasawisma;
  final String? statusIbu;
  final String? tanggalHamil;
  final String? tanggalMelahirkan;
  final String? namaBayi;
  final String? jenisKelaminBayi;
  final String? tanggalLahirBayi;
  final String? akteKelahiran;
  final String? statusKematian;
  final String? namaMeninggal;
  final String? tanggalMeninggal;
  final String? sebabMeninggal;
  final int configYear;

  CatatanKelahiranKematianModel({
    required this.id,
    this.idWargaIbu,
    this.namaIbu,
    this.idWargaSuami,
    this.namaSuami,
    this.noKk,
    this.idGroupDasawisma,
    this.statusIbu,
    this.tanggalHamil,
    this.tanggalMelahirkan,
    this.namaBayi,
    this.jenisKelaminBayi,
    this.tanggalLahirBayi,
    this.akteKelahiran,
    this.statusKematian,
    this.namaMeninggal,
    this.tanggalMeninggal,
    this.sebabMeninggal,
    required this.configYear,
  });

  factory CatatanKelahiranKematianModel.fromJson(Map<String, dynamic> json) {
    return CatatanKelahiranKematianModel(
      id: _parseInt(json['id']),
      idWargaIbu: json['id_warga_ibu']?.toString(),
      namaIbu: json['nama_ibu']?.toString(),
      idWargaSuami: json['id_warga_suami']?.toString(),
      namaSuami: json['nama_suami']?.toString(),
      noKk: json['no_kk']?.toString(),
      idGroupDasawisma: _parseIntNullable(json['id_group_dasawisma']),
      statusIbu: json['status_ibu']?.toString(),
      tanggalHamil: json['tanggal_hamil']?.toString(),
      tanggalMelahirkan: json['tanggal_melahirkan']?.toString(),
      namaBayi: json['nama_bayi']?.toString(),
      jenisKelaminBayi: json['jenis_kelamin_bayi']?.toString(),
      tanggalLahirBayi: json['tanggal_lahir_bayi']?.toString(),
      akteKelahiran: json['akte_kelahiran']?.toString(),
      statusKematian: json['status_kematian']?.toString(),
      namaMeninggal: json['nama_meninggal']?.toString(),
      tanggalMeninggal: json['tanggal_meninggal']?.toString(),
      sebabMeninggal: json['sebab_meninggal']?.toString(),
      configYear: _parseInt(json['config_year']),
    );
  }
}
