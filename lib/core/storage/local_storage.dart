import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorage {
  static const _storage = FlutterSecureStorage();

  // Keys
  static const _tokenKey = 'auth_token';
  static const _userKey = 'user_data';
  static const _baseUrlKey = 'base_url';
  static const _rememberEmailKey = 'remember_email';

  // Token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // User data
  static Future<void> saveUserData(String userData) async {
    await _storage.write(key: _userKey, value: userData);
  }

  static Future<String?> getUserData() async {
    return await _storage.read(key: _userKey);
  }

  static Future<void> deleteUserData() async {
    await _storage.delete(key: _userKey);
  }

  // Remember email
  static Future<void> saveRememberedEmail(String email) async {
    await _storage.write(key: _rememberEmailKey, value: email);
  }

  static Future<String?> getRememberedEmail() async {
    return await _storage.read(key: _rememberEmailKey);
  }

  // Base URL
  static Future<void> saveBaseUrl(String url) async {
    await _storage.write(key: _baseUrlKey, value: url);
  }

  static Future<String?> getBaseUrl() async {
    return await _storage.read(key: _baseUrlKey);
  }

  // Clear all
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
