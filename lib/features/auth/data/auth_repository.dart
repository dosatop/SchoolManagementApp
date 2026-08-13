import 'package:app/core/Dtos/auth_dtos/login_request.dart';
import 'package:app/core/Dtos/auth_dtos/login_response.dart';
import 'package:app/core/storage/storage_service.dart';
import 'package:app/features/auth/data/auth_api.dart';
import 'package:app/features/auth/models/signup_request.dart';

class AuthRepository {
  final AuthApi authApi;

  final StorageService storage;

  AuthRepository({required this.authApi, required this.storage});

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await authApi.login(request);

    await _saveAuthData(response);

    return response;
  }

  Future<String> signup(SignupRequest request) async {
    final response = await authApi.signup(request);

    // await _saveAuthData(response);

    return response;
  }

  Future<void> _saveAuthData(LoginResponse response) async {
    await storage.saveToken(response.tokenResponse.accessToken);

    await storage.saveRefreshToken(response.tokenResponse.refreshToken);
  }

  Future<void> logout() async {
    await authApi.logout();

    await storage.deleteToken();
    await storage.deleteRefreshToken();
  }
}
