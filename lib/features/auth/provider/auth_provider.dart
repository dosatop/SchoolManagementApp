import 'package:app/core/Dtos/auth_dtos/login_request.dart';
import 'package:app/core/network/dio_provider.dart';
import 'package:app/features/auth/data/auth_api.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/auth/models/signup_request.dart';
import 'package:app/features/user/provider/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthState {
  final bool isAuthenticated;

  const AuthState({this.isAuthenticated = false});
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);

  final authApi = AuthApi(dioClient);

  final storage = ref.read(secureStorageProvider);

  return AuthRepository(authApi: authApi, storage: storage);
});

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    return const AuthState(isAuthenticated: false);
  }

  Future<String?> login(LoginRequest request) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(authRepositoryProvider);

      final response = await repository.login(request);

      ref.read(userProvider.notifier).state = response;

      state = AsyncData(const AuthState(isAuthenticated: true));

      return null;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return error.toString();
    }
  }

  Future<String?> signup(SignupRequest request) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(authRepositoryProvider);

      final response = await repository.signup(request);

      ref.read(userProvider.notifier).state = response;

      state = AsyncData(const AuthState(isAuthenticated: true));
      return null;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return error.toString();
    }
  }

  Future<void> logout() async {
    ref.read(userProvider.notifier).state = null;

    state = const AsyncData(AuthState(isAuthenticated: false));
  }
}
