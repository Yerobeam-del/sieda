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
      id: json['id'] ?? 0,
      configYear: json['config_year'] ?? 0,
      dusun: json['dusun'],
      kegiatan: json['kegiatan'],
      volumeKegiatan: json['volume_kegiatan']?.toString(),
      metode: json['metode'],
      jumlahSasaran: json['jumlah_sasaran']?.toString(),
      keterangan: json['keterangan'],
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
      id: json['id'] ?? 0,
      configYear: json['config_year'] ?? 0,
      dusun: json['dusun'],
      jumlahKeluarga: json['jumlah_keluarga']?.toString(),
      jumlahPenduduk: json['jumlah_penduduk']?.toString(),
      jumlahKader: json['jumlah_kader']?.toString(),
      keterangan: json['keterangan'],
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
      id: json['id'] ?? 0,
      idWargaIbu: json['id_warga_ibu'],
      namaIbu: json['nama_ibu'],
      idWargaSuami: json['id_warga_suami'],
      namaSuami: json['nama_suami'],
      noKk: json['no_kk'],
      idGroupDasawisma: json['id_group_dasawisma'],
      statusIbu: json['status_ibu'],
      tanggalHamil: json['tanggal_hamil'],
      tanggalMelahirkan: json['tanggal_melahirkan'],
      namaBayi: json['nama_bayi'],
      jenisKelaminBayi: json['jenis_kelamin_bayi'],
      tanggalLahirBayi: json['tanggal_lahir_bayi'],
      akteKelahiran: json['akte_kelahiran'],
      statusKematian: json['status_kematian'],
      namaMeninggal: json['nama_meninggal'],
      tanggalMeninggal: json['tanggal_meninggal'],
      sebabMeninggal: json['sebab_meninggal'],
      configYear: json['config_year'] ?? 0,
    );
  }
}
