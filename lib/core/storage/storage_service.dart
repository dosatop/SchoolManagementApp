import 'dart:convert';

import 'package:app/core/Dtos/auth_dtos/login_info_dto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'accessToken', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'accessToken');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'accessToken');
  }

  // Refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: 'refreshToken', value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refreshToken');
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: 'refreshToken');
  }

  // Clear authentication
  Future<void> clearAuth() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
  }

  Future<void> saveLoginInfo(
    String email,
    String password,
    bool rememberMe,
  ) async {
    final LoginInfoDto loginInfo = LoginInfoDto(
      email: email,
      password: password,
      rememberMe: rememberMe,
    );

    await _storage.write(
      key: 'loginInfo',
      value: jsonEncode(loginInfo.toJson()),
    );
  }

  Future<LoginInfoDto?> getLoginInfo() async {
    final value = await _storage.read(key: 'loginInfo');

    if (value == null) return null;

    return LoginInfoDto.fromJson(jsonDecode(value));
  }

  Future<void> clearLoginInfo() async {
    await _storage.delete(key: 'loginInfo');
  }
}
