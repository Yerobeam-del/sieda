import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exception.dart';
import '../core/storage/local_storage.dart';
import '../database/local_database.dart';
import '../models/dashboard_model.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardModel? _dashboard;
  DetailDusun? _detailDusun;
  bool _isLoading = false;
  ApiException? _error;
  bool _hasCachedData = false;
  String? _apiMessage;

  DashboardModel? get dashboard => _dashboard;
  DetailDusun? get detailDusun => _detailDusun;
  bool get isLoading => _isLoading;
  ApiException? get error => _error;
  bool get hasCachedData => _hasCachedData;
  String? get apiMessage => _apiMessage;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        _error = ApiException(message: 'Silakan login terlebih dahulu.');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final client = ApiClient(token: token);
      final response = await client.get(ApiEndpoints.dashboard);
      final data = response['data'] as Map<String, dynamic>;
      _dashboard = DashboardModel.fromJson(data);
      _hasCachedData = true;
      _apiMessage = response['message'] as String?;

      // Cache dashboard data locally
      try {
        await LocalDatabase().cacheDashboard(data);
      } catch (_) {
        // Cache failure is non-critical
      }
    } on ApiException catch (e) {
      _error = e;
      // Try to load from cache
      await _loadCachedDashboard();
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat data dashboard.');
      await _loadCachedDashboard();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadCachedDashboard() async {
    try {
      final cached = await LocalDatabase().getCachedDashboard();
      if (cached != null && cached['json_data'] != null) {
        final data = jsonDecode(cached['json_data'] as String) as Map<String, dynamic>;
        _dashboard = DashboardModel.fromJson(data);
        _hasCachedData = true;
        debugPrint('[Dashboard] Loaded from cache');
      }
    } catch (_) {
      debugPrint('[Dashboard] Cache load failed');
    }
  }

  Future<void> loadDetailDusun(int dusunId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        _error = ApiException(message: 'Silakan login terlebih dahulu.');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final client = ApiClient(token: token);
      final response = await client.get(ApiEndpoints.dashboardDetailDusun(dusunId));
      _detailDusun = DetailDusun.fromJson(response['data']);
    } on ApiException catch (e) {
      _error = e;
    } catch (e) {
      _error = ApiException(message: 'Gagal memuat detail dusun.');
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
