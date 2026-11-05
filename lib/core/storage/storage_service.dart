import 'dart:convert';

import 'package:app/core/Dtos/auth_dtos/login_info_dto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // ================================================================
  // IN-MEMORY CACHE
  // ================================================================
  // Secure storage reads go through the platform and are slow. The
  // token is read on EVERY request, so keep it in memory after the
  // first read. Static so every StorageService() instance shares it.

  static String? _accessToken;
  static bool _accessTokenLoaded = false;

  static String? _refreshToken;
  static bool _refreshTokenLoaded = false;

  static bool? _onboardingSeen;

  static const _accessTokenKey = 'accessToken';
  static const _refreshTokenKey = 'refreshToken';
  static const _loginInfoKey = 'loginInfo';
  static const _onboardingKey = 'onboardingSeen';

  // ================================================================
  // ACCESS TOKEN
  // ================================================================

  Future<void> saveToken(String token) async {
    _accessToken = token;
    _accessTokenLoaded = true;
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getToken() async {
    if (_accessTokenLoaded) return _accessToken;

    _accessToken = await _storage.read(key: _accessTokenKey);
    _accessTokenLoaded = true;
    return _accessToken;
  }

  Future<void> deleteToken() async {
    _accessToken = null;
    _accessTokenLoaded = true;
    await _storage.delete(key: _accessTokenKey);
  }

  // ================================================================
  // REFRESH TOKEN
  // ================================================================

  Future<void> saveRefreshToken(String token) async {
    _refreshToken = token;
    _refreshTokenLoaded = true;
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    if (_refreshTokenLoaded) return _refreshToken;

    _refreshToken = await _storage.read(key: _refreshTokenKey);
    _refreshTokenLoaded = true;
    return _refreshToken;
  }

  Future<void> deleteRefreshToken() async {
    _refreshToken = null;
    _refreshTokenLoaded = true;
    await _storage.delete(key: _refreshTokenKey);
  }

  // ================================================================
  // CLEAR AUTH (logout)
  // ================================================================
  // Only tokens. Onboarding and "remember me" are kept, so logging out
  // doesn't show the intro slides again.

  Future<void> clearAuth() async {
    _accessToken = null;
    _accessTokenLoaded = true;
    _refreshToken = null;
    _refreshTokenLoaded = true;

    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  /// Forget the in-memory tokens so the next read comes from storage.
  /// Call after anything writes tokens without going through this class.
  static void resetCache() {
    _accessToken = null;
    _accessTokenLoaded = false;
    _refreshToken = null;
    _refreshTokenLoaded = false;
  }
  
  // ================================================================
  // REMEMBER ME
  // ================================================================

  Future<void> saveLoginInfo(
    String email,
    String password,
    bool rememberMe,
  ) async {
    final loginInfo = LoginInfoDto(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );

    await _storage.write(
      key: _loginInfoKey,
      value: jsonEncode(loginInfo.toJson()),
    );
  }

  Future<LoginInfoDto?> getLoginInfo() async {
    final value = await _storage.read(key: _loginInfoKey);

    if (value == null) return null;

    try {
      return LoginInfoDto.fromJson(jsonDecode(value));
    } catch (_) {
      // Corrupt/old format — forget it instead of crashing the login page.
      await clearLoginInfo();
      return null;
    }
  }

  Future<void> clearLoginInfo() async {
    await _storage.delete(key: _loginInfoKey);
  }

  // ================================================================
  // ONBOARDING (shown once per device)
  // ================================================================

  Future<bool> hasSeenOnboarding() async {
    if (_onboardingSeen != null) return _onboardingSeen!;

    _onboardingSeen = await _storage.read(key: _onboardingKey) == 'true';
    return _onboardingSeen!;
  }

  Future<void> setOnboardingSeen() async {
    _onboardingSeen = true;
    await _storage.write(key: _onboardingKey, value: 'true');
  }

  /// For testing: show the slides again on next launch.
  Future<void> resetOnboarding() async {
    _onboardingSeen = false;
    await _storage.delete(key: _onboardingKey);
  }
}
