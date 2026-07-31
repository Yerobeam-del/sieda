class ApiEndpoints {
  /// Base URL untuk API SIEDA.
  ///
  /// Seluruh API sudah tersedia di domain sieda.pkktoba.id via Apache.
  /// Port 8004 (php artisan serve) hanya untuk development lokal.
  static const String baseUrl = 'https://sieda.pkktoba.id/api/v1';

  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String logoutAll = '/auth/logout-all';
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/profile';

  // Dashboard
  static const String dashboard = '/dashboard';
  static const String dashboardConfig = '/dashboard/config';
  static String dashboardDetailDusun(int dusunId) => '/dashboard/detail-dusun/$dusunId';

  // Penduduk
  static const String penduduk = '/penduduk';
  static String pendudukDetail(String nik) => '/penduduk/$nik';

  // Keluarga
  static const String keluarga = '/keluarga';
  static String keluargaDetail(String noKk) => '/keluarga/$noKk';
  static String keluargaAnggota(String noKk) => '/keluarga/$noKk/anggota';
  static String keluargaAnggotaRemove(String noKk, String nik) =>
      '/keluarga/$noKk/anggota/$nik';

  // Dasawisma
  static const String dasawismaKelompok = '/dasawisma/kelompok';
  static String dasawismaKelompokDetail(int id) => '/dasawisma/kelompok/$id';
  static const String dasawismaKeluarga = '/dasawisma/keluarga';
  static String dasawismaKeluargaDetail(String noKk) => '/dasawisma/keluarga/$noKk';
  static const String dasawismaRingkasan = '/dasawisma/ringkasan-per-dusun';
  static const String dasawismaRecapKesehatan = '/dasawisma/recap-kesehatan';

  // Rekapitulasi
  static const String rekapitulasiAll = '/rekapitulasi/all';
  static const String rekapitulasiDataUmum = '/rekapitulasi/data-umum';
  static const String rekapitulasiPokjaSatu = '/rekapitulasi/pokja-satu';
  static const String rekapitulasiPokjaDua = '/rekapitulasi/pokja-dua';
  static const String rekapitulasiPokjaTiga = '/rekapitulasi/pokja-tiga';
  static const String rekapitulasiPokjaEmpat = '/rekapitulasi/pokja-empat';
  static const String rekapitulasiKelahiranKematian = '/rekapitulasi/kelahiran-kematian';
  static const String rekapitulasiDataKesehatan = '/rekapitulasi/data-kesehatan';

  // Catatan Kelahiran & Kematian
  static const String catatanKelahiranKematian = '/catatan-kelahiran-kematian';
  static String catatanDetail(int id) => '/catatan-kelahiran-kematian/$id';

  // References
  static const String referencesAll = '/references/all';
  static const String referencesDusun = '/references/dusun';
  static const String referencesAgama = '/references/agama';
  static const String referencesPekerjaan = '/references/pekerjaan';
  static const String referencesPendidikan = '/references/pendidikan';
  static const String referencesStatusPerkawinan = '/references/status-perkawinan';

  // Letter Archive
  static const String letterArchive = '/letter-archive';
  static String letterArchiveDetail(int id) => '/letter-archive/$id';
  static const String letterArchiveTypes = '/letter-archive/types';
}
