import 'package:app/core/Dtos/auth_dtos/login_request.dart';
import 'package:app/core/network/dio_provider.dart';
import 'package:app/core/storage/storage_service.dart';
import 'package:app/features/auth/data/auth_api.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/auth/models/signup_request.dart';
import 'package:app/features/user/models/user_model.dart';
import 'package:app/features/user/provider/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ====================================================================
// AUTH PROVIDER
// ====================================================================
// Data providers (admin dashboard, student profile, …) WATCH this via
// signedInAs(), so they reload by themselves on login / logout.
// This file must NOT import or invalidate them — that would create a
// circular dependency.

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

  AuthState({this.isAuthenticated = false, this.role, this.user});

  factory AuthState.loggedOut() => AuthState();
}

// ====================================================================
// AUTH REPOSITORY PROVIDER
// ====================================================================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  final authApi = AuthApi(dioClient);
  final storage = ref.read(secureStorageProvider);

  return AuthRepository(authApi: authApi, storage: storage);
});

// ====================================================================
// AUTH NOTIFIER
// ====================================================================

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async => AuthState.loggedOut();

  // ==================================================================
  // LOGIN
  // ==================================================================

  Future<String?> login(LoginRequest request) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(authRepositoryProvider);

      // Saves the new token inside the repository.
      final response = await repository.login(request);

      // The repository may write the token without going through
      // StorageService, so drop the cached (old) token and re-read it.
      StorageService.resetCache();

      ref.read(userProvider.notifier).state = response;

      // Setting the new state makes every role-guarded provider reload
      // for this account (and drop the previous account's data).
      state = AsyncData(
        AuthState(
          isAuthenticated: true,
          role: response.user.role,
          user: response.user,
        ),
      );

      return null;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
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

      state = AsyncData(AuthState.loggedOut());
      return null;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return error.toString();
    }
  }

  // ==================================================================
  // LOGOUT
  // ==================================================================
  // Always logs out locally, even if the server call fails.

  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (error) {
      debugPrint('LOGOUT API ERROR (ignored): $error');
    }

    // Make sure no token survives, whichever storage the repo used.
    await StorageService().clearAuth();
    StorageService.resetCache();

    ref.read(userProvider.notifier).state = null;

    // Logged-out state → every role-guarded provider clears itself.
    state = AsyncData(AuthState.loggedOut());
  }
}

// ====================================================================
// ROLE GUARD
// ====================================================================
// Use at the top of a provider's build() so it never calls another
// role's endpoints. Because it WATCHES authProvider, the provider also
// re-runs automatically when someone logs in or out.
//
// Roles: 'SuperAdmin', 'Admin', 'Teacher', 'Parent', 'Student'.

bool signedInAs(Ref ref, String role) =>
    ref.watch(authProvider).valueOrNull?.role == role;
