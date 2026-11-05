import 'package:app/core/Dtos/auth_dtos/login_request.dart';
import 'package:app/core/network/dio_provider.dart';
import 'package:app/core/storage/storage_service.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:app/features/auth/data/auth_api.dart';
import 'package:app/features/auth/data/auth_repository.dart';
import 'package:app/features/auth/models/signup_request.dart';
import 'package:app/features/students/provider/students_provider.dart';
import 'package:app/features/user/models/user_model.dart';
import 'package:app/features/user/provider/user_provider.dart';
import 'package:flutter/foundation.dart';
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
  // CLEAR CACHED DATA FROM THE PREVIOUS ACCOUNT
  // ==================================================================
  // These providers are not auto-disposed, so without this a new login
  // can show the previous account's data — or its cached 401/403
  // ("Please sign in again"). Add teacher/parent providers here too.

  void _clearAccountData() {
    ref.invalidate(studentProfileProvider);
    ref.invalidate(studentSubjectsProvider);
    ref.invalidate(studentClassProvider);
    ref.invalidate(studentAssignmentsProvider);
    ref.invalidate(studentAttendanceProvider);
    ref.invalidate(studentResultsProvider);
    ref.invalidate(adminDashboardProvider);
  }

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

      // Nothing from the previous account may survive.
      _clearAccountData();

      ref.read(userProvider.notifier).state = response;

      // Only now let the router open the dashboard.
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
    _clearAccountData();

    state = AsyncData(AuthState.loggedOut());
  }
}
