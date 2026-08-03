import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import '../core/api/api_auth_stream.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/api_exception.dart';
import '../core/storage/local_storage.dart';
import '../models/user_model.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.uninitialized;
  UserModel? _user;
  ApiException? _error;
  String? _rememberedEmail;

  /// Completer yang resolve saat _initialize() selesai.
  /// Splash screen meng-await ini untuk menghindari race condition
  /// (status masih uninitialized saat pengecekan rute).
  final Completer<void> _readyCompleter = Completer<void>();
  Future<void> get ready => _readyCompleter.future;

  /// Subscription ke event 401 global dari ApiClient — memicu force logout.
  StreamSubscription<int>? _authSub;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  ApiException? get error => _error;
  String? get rememberedEmail => _rememberedEmail;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isUninitialized => _status == AuthStatus.uninitialized;

  AuthProvider() {
    // Dengarkan event 401 dari mana pun (mis. request gagal di provider lain
    // saat token kadaluarsa 30 hari di tengah pemakaian).
    _authSub = ApiAuthStream.stream.listen((_) async {
      // Hindari loop — hanya logout jika state saat ini authenticated.
      if (_status == AuthStatus.authenticated) {
        await _forceLogout();
      }
    });
    _initialize();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      _rememberedEmail = await LocalStorage.getRememberedEmail();
      final token = await LocalStorage.getToken();

      if (token == null || token.isEmpty) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      // Instagram-style: restore dari cache dulu, langsung authenticated
      final userData = await LocalStorage.getUserData();
      if (userData != null) {
        _user = UserModel.fromJson(json.decode(userData));
      }

      // PASTIKAN status di-set SEBELUM background refresh,
      // agar splash screen selalu melihat status yang definitif
      _status = AuthStatus.authenticated;
      notifyListeners();

      // Background refresh: coba verifikasi token ke server
      if (userData != null) {
        // Refresh di background tanpa await
        _refreshUserData(token);
      } else {
        // Tidak ada cache — tunggu hasil refresh
        await _refreshUserData(token);
      }
    } catch (_) {
      // Defensive: jika restore gagal total, anggap belum login.
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } finally {
      // Selalu lepaskan splash screen, walau terjadi error.
      if (!_readyCompleter.isCompleted) {
        _readyCompleter.complete();
      }
    }
  }

  /// Refresh data user dari server di background.
  /// - Jika sukses: update data user & cache.
  /// - Jika 401 (token benar-benar kadaluarsa/dicabut): paksa logout.
  /// - Jika error jaringan (offline/server 5xx): tetap pakai data cache.
  Future<void> _refreshUserData(String token) async {
    try {
      final client = ApiClient(token: token);
      final response = await client.get(ApiEndpoints.me);
      final userJson = response['data'] as Map<String, dynamic>;
      _user = UserModel.fromJson(userJson);
      await LocalStorage.saveUserData(json.encode(userJson));
      _status = AuthStatus.authenticated;
    } on ApiException catch (e) {
      // 401 = token tidak valid lagi -> paksa logout.
      if (e.statusCode == 401) {
        await _forceLogout();
      }
      // Error lain (0 = koneksi gagal, 5xx) -> biarkan pakai cache.
    } catch (_) {
      // Error tak terduga -> tetap pakai cache jika ada user.
      if (_user == null) {
        await _forceLogout();
      }
    }
    notifyListeners();
  }

  /// Hapus token & data user, paksa status menjadi unauthenticated.
  /// Dipanggil otomatis oleh ApiAuthStream saat endpoint mana pun mengembalikan 401
  /// (token kedaluwarsa setelah 30 hari, atau dicabut dari server).
  Future<void> _forceLogout() async {
    await LocalStorage.deleteToken();
    await LocalStorage.deleteUserData();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners(); // Wajib — UI (router guard) bereaksi & pindah ke LoginScreen
  }

  Future<bool> login(String email, String password, {bool remember = false}) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final client = ApiClient();
      final response = await client.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
          'device_name': 'siEDA Mobile',
        },
      );

      final data = response['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      final userJson = data['user'] as Map<String, dynamic>;

      _user = UserModel.fromJson({
        ...userJson,
        'token': token,
      });

      // Save to local storage
      await LocalStorage.saveToken(token);
      await LocalStorage.saveUserData(json.encode(userJson));
      if (remember) {
        await LocalStorage.saveRememberedEmail(email);
      } else {
        await LocalStorage.saveRememberedEmail('');
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = ApiException(message: 'Terjadi kesalahan: ${e.toString()}');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final token = await LocalStorage.getToken();
      if (token != null) {
        final client = ApiClient(token: token);
        await client.post(ApiEndpoints.logout);
      }
    } catch (_) {
      // Ignore logout errors
    }

    await LocalStorage.deleteToken();
    await LocalStorage.deleteUserData();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> logoutAll() async {
    try {
      final token = await LocalStorage.getToken();
      if (token != null) {
        final client = ApiClient(token: token);
        await client.post(ApiEndpoints.logoutAll);
      }
    } catch (_) {}

    await LocalStorage.clearAll();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? name,
    String? username,
    String? email,
    String? currentPassword,
    String? password,
    String? passwordConfirmation,
  }) async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) return false;

      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (username != null) data['username'] = username;
      if (email != null) data['email'] = email;
      if (password != null) {
        // Backend kini mewajibkan current_password saat mengubah password
        data['current_password'] = currentPassword;
        data['password'] = password;
        data['password_confirmation'] = passwordConfirmation ?? password;
      }

      final client = ApiClient(token: token);
      final response = await client.put(ApiEndpoints.updateProfile, data: data);
      final userJson = response['data'] as Map<String, dynamic>;
      _user = UserModel.fromJson(userJson);
      await LocalStorage.saveUserData(json.encode(userJson));
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e;
      notifyListeners();
      return false;
    } catch (e) {
      _error = ApiException(message: 'Gagal memperbarui profile.');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
