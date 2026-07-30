import 'package:flutter/foundation.dart';
import 'dart:convert';
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

  AuthStatus get status => _status;
  UserModel? get user => _user;
  ApiException? get error => _error;
  String? get rememberedEmail => _rememberedEmail;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _initialize();
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

      // Try to restore user from local storage first
      final userData = await LocalStorage.getUserData();
      if (userData != null) {
        _user = UserModel.fromJson(json.decode(userData));
      }

      // Verify token is still valid
      final client = ApiClient(token: token);
      final response = await client.get(ApiEndpoints.me);
      final userJson = response['data'] as Map<String, dynamic>;
      _user = UserModel.fromJson(userJson);
      await LocalStorage.saveUserData(json.encode(userJson));
      _status = AuthStatus.authenticated;
    } catch (_) {
      // Jika API /auth/me gagal (offline/server error), jangan langsung hapus token.
      // Cukup set status authenticated jika user data masih ada di local storage.
      if (_user != null) {
        // Pertahankan sesi dari cache, user tetap bisa pakai app secara offline
        _status = AuthStatus.authenticated;
      } else {
        await LocalStorage.deleteToken();
        await LocalStorage.deleteUserData();
        _status = AuthStatus.unauthenticated;
      }
    }
    notifyListeners();
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

  Future<bool> updateProfile({String? name, String? username, String? email, String? password, String? passwordConfirmation}) async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) return false;

      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (username != null) data['username'] = username;
      if (email != null) data['email'] = email;
      if (password != null) {
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
