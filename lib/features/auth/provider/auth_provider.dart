import 'package:app/core/Dtos/auth_dtos/login_request.dart';
import 'package:app/core/network/dio_provider.dart';
import 'package:app/features/auth/data/auth_api.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/auth/models/signup_request.dart';
import 'package:app/features/user/models/user_model.dart';
import 'package:app/features/user/provider/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ====================================================================
// AUTH PROVIDER
// ====================================================================

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// ====================================================================
// AUTH STATE
// ====================================================================

class AuthState {
  final bool isAuthenticated;
  final String? role;
  final UserModel? user;

  AuthState({
    this.isAuthenticated = false,
    this.role,
    this.user,
  });
}

// ====================================================================
// AUTH REPOSITORY PROVIDER
// ====================================================================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);

  final authApi = AuthApi(dioClient);

  final storage = ref.read(secureStorageProvider);

  return AuthRepository(
    authApi: authApi,
    storage: storage,
  );
});

// ====================================================================
// AUTH NOTIFIER
// ====================================================================

class AuthNotifier extends AsyncNotifier<AuthState> {
  // ==================================================================
  // INITIAL STATE
  // ==================================================================

  @override
  Future<AuthState> build() async {
    return AuthState(
      isAuthenticated: false,
      role: null,
      user: null,
    );
  }

  // ==================================================================
  // LOGIN
  // ==================================================================

  Future<String?> login(LoginRequest request) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(authRepositoryProvider);

      // --------------------------------------------------------------
      // Call API
      // --------------------------------------------------------------

      final response = await repository.login(request);

      // --------------------------------------------------------------
      // Store complete login response
      // --------------------------------------------------------------

      ref.read(userProvider.notifier).state = response;

      // --------------------------------------------------------------
      // Store authentication state
      //
      // IMPORTANT:
      // response.user contains:
      //
      // - fullName
      // - email
      // - phoneNumber
      // - schoolId
      // - role
      // --------------------------------------------------------------

      state = AsyncData(
        AuthState(
          isAuthenticated: true,
          role: response.user.role,
          user: response.user,
        ),
      );

      return null;
    } catch (error, stackTrace) {
      state = AsyncError(
        error,
        stackTrace,
      );

      return error.toString();
    }
  }

  // ==================================================================
  // SIGN UP
  // ==================================================================

  Future<String?> signup(SignupRequest request) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(authRepositoryProvider);

      await repository.signup(request);

      state = AsyncData(
        AuthState(
          isAuthenticated: false,
          role: null,
          user: null,
        ),
      );

      return null;
    } catch (error, stackTrace) {
      state = AsyncError(
        error,
        stackTrace,
      );

      return error.toString();
    }
  }

  // ==================================================================
  // LOGOUT
  // ==================================================================

  Future<void> logout() async {
    try {
      final repository = ref.read(authRepositoryProvider);

      await repository.logout();

      // Clear user data
      ref.read(userProvider.notifier).state = null;

      // Clear authentication state
      state = AsyncData(
        AuthState(
          isAuthenticated: false,
          role: null,
          user: null,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncError(
        error,
        stackTrace,
      );
    }
  }
}