class ReferenceItem {
  final int id;
  final String nama;

  ReferenceItem({required this.id, required this.nama});

  factory ReferenceItem.fromJson(Map<String, dynamic> json) {
    return ReferenceItem(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
    );
  }
}

class ReferenceData {
  final List<ReferenceItem> dusun;
  final List<ReferenceItem> agama;
  final List<ReferenceItem> pekerjaan;
  final List<ReferenceItem> pendidikan;
  final List<ReferenceItem> statusPerkawinan;
  final List<ReferenceItem> statusKeluarga;
  final List<ReferenceItem> peranKeluarga;
  final List<ReferenceItem> jabatanPkk;
  final List<ReferenceItem> jenisAkseptor;
  final List<ReferenceItem> jenisKelompokBelajar;
  final List<ReferenceItem> jenisKoperasi;
  final List<ReferenceItem> kebutuhanKhusus;
  final List<ReferenceItem> kelompokDasawisma;

  ReferenceData({
    this.dusun = const [],
    this.agama = const [],
    this.pekerjaan = const [],
    this.pendidikan = const [],
    this.statusPerkawinan = const [],
    this.statusKeluarga = const [],
    this.peranKeluarga = const [],
    this.jabatanPkk = const [],
    this.jenisAkseptor = const [],
    this.jenisKelompokBelajar = const [],
    this.jenisKoperasi = const [],
    this.kebutuhanKhusus = const [],
    this.kelompokDasawisma = const [],
  });

  factory ReferenceData.fromJson(Map<String, dynamic> json) {
    List<ReferenceItem> parseList(String key) {
      final list = json[key] as List<dynamic>?;
      if (list == null) return [];
      return list.map((e) => ReferenceItem.fromJson(e as Map<String, dynamic>)).toList();
    }

    return ReferenceData(
      dusun: parseList('dusun'),
      agama: parseList('agama'),
      pekerjaan: parseList('pekerjaan'),
      pendidikan: parseList('pendidikan'),
      statusPerkawinan: parseList('status_perkawinan'),
      statusKeluarga: parseList('status_keluarga'),
      peranKeluarga: parseList('peran_keluarga'),
      jabatanPkk: parseList('jabatan_pkk'),
      jenisAkseptor: parseList('jenis_akseptor'),
      jenisKelompokBelajar: parseList('jenis_kelompok_belajar'),
      jenisKoperasi: parseList('jenis_koperasi'),
      kebutuhanKhusus: parseList('kebutuhan_khusus'),
      kelompokDasawisma: parseList('kelompok_dasawisma'),
    );
  }
}

class KelompokDasawismaItem {
  final int id;
  final String nama;
  final String? dusun;
  final String? kader;

  KelompokDasawismaItem({
    required this.id,
    required this.nama,
    this.dusun,
    this.kader,
  });

  factory KelompokDasawismaItem.fromJson(Map<String, dynamic> json) {
    String? extractDusun(dynamic val) {
      if (val is Map) return val['nama']?.toString();
      return val?.toString();
    }

    return KelompokDasawismaItem(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      dusun: extractDusun(json['dusun']),
      kader: json['kader']?.toString(),
    );
  }

  String get label => '$nama${dusun != null ? ' ($dusun)' : ''}';
}
