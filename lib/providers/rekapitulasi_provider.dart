import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exception.dart';
import '../core/storage/local_storage.dart';
import '../models/rekapitulasi_model.dart';

class RekapitulasiProvider extends ChangeNotifier {
  List<DataUmumPKK> _dataUmum = [];
  List<RekapitulasiModel> _pokjaSatu = [];
  List<RekapitulasiModel> _pokjaDua = [];
  List<RekapitulasiModel> _pokjaTiga = [];
  List<RekapitulasiModel> _pokjaEmpat = [];
  List<CatatanKelahiranKematianModel> _catatanList = [];
  bool _isLoading = false;
  String? _activeTab;
  ApiException? _error;

  List<DataUmumPKK> get dataUmum => _dataUmum;
  List<RekapitulasiModel> get pokjaSatu => _pokjaSatu;
  List<RekapitulasiModel> get pokjaDua => _pokjaDua;
  List<RekapitulasiModel> get pokjaTiga => _pokjaTiga;
  List<RekapitulasiModel> get pokjaEmpat => _pokjaEmpat;
  List<CatatanKelahiranKematianModel> get catatanList => _catatanList;
  bool get isLoading => _isLoading;
  String? get activeTab => _activeTab;
  ApiException? get error => _error;

  Future<void> loadDataUmum() async {
    _isLoading = true;
    _activeTab = 'data_umum';
    _error = null;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final response = await client.get(ApiEndpoints.rekapitulasiDataUmum);
      final data = response['data'] as List<dynamic>;
      _dataUmum = data.map((e) => DataUmumPKK.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat data umum.');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPokjaSatu() async {
    _isLoading = true;
    _activeTab = 'pokja_satu';
    _error = null;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final response = await client.get(ApiEndpoints.rekapitulasiPokjaSatu);
      final data = response['data'] as List<dynamic>;
      _pokjaSatu = data.map((e) => RekapitulasiModel.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat data Pokja 1.');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPokjaDua() async {
    _isLoading = true;
    _activeTab = 'pokja_dua';
    _error = null;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final response = await client.get(ApiEndpoints.rekapitulasiPokjaDua);
      final data = response['data'] as List<dynamic>;
      _pokjaDua = data.map((e) => RekapitulasiModel.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat data Pokja 2.');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPokjaTiga() async {
    _isLoading = true;
    _activeTab = 'pokja_tiga';
    _error = null;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final response = await client.get(ApiEndpoints.rekapitulasiPokjaTiga);
      final data = response['data'] as List<dynamic>;
      _pokjaTiga = data.map((e) => RekapitulasiModel.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat data Pokja 3.');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPokjaEmpat() async {
    _isLoading = true;
    _activeTab = 'pokja_empat';
    _error = null;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final response = await client.get(ApiEndpoints.rekapitulasiPokjaEmpat);
      final data = response['data'] as List<dynamic>;
      _pokjaEmpat = data.map((e) => RekapitulasiModel.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat data Pokja 4.');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadCatatan() async {
    _isLoading = true;
    _activeTab = 'catatan';
    _error = null;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      final client = ApiClient(token: token!);
      final response = await client.get(ApiEndpoints.catatanKelahiranKematian);
      final data = response['data'] as List<dynamic>;
      _catatanList = data.map((e) => CatatanKelahiranKematianModel.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat catatan kelahiran/kematian.');
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
