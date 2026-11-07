import 'package:app/core/network/dio_provider.dart';
import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:app/features/super_admin/data/super_admin_api.dart';
import 'package:app/features/super_admin/data/super_admin_repository.dart';
import 'package:app/features/super_admin/models/create_school_request.dart';
import 'package:app/features/super_admin/models/school_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final superAdminRepositoryProvider = Provider<SuperAdminRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);

  final api = SuperAdminApi(dioClient);

  return SuperAdminRepository(api: api);
});

final superAdminProvider =
    AsyncNotifierProvider<SuperAdminNotifier, List<SchoolModel>>(
      SuperAdminNotifier.new,
    );

class SuperAdminNotifier extends AsyncNotifier<List<SchoolModel>> {
  // ----------------------------------------------------------------
  // Initial load
  // ----------------------------------------------------------------
  // Loads the schools as soon as something watches this provider, so
  // the page no longer needs to call getSchools() in initState.
  // Only a super admin ever calls /api/schools.

  @override
  Future<List<SchoolModel>> build() async {
    if (!signedInAs(ref, 'SuperAdmin')) return [];

    return ref.read(superAdminRepositoryProvider).getSchools();
  }

  // ----------------------------------------------------------------
  // Get Schools (refresh)
  // ----------------------------------------------------------------
  // Keeps the current list on screen while reloading; only shows the
  // loading state the very first time.

  Future<List<SchoolModel>> getSchools() async {
    state = const AsyncLoading<List<SchoolModel>>().copyWithPrevious(state);

    try {
      final schools = await ref.read(superAdminRepositoryProvider).getSchools();

      state = AsyncData(schools);

      return schools;
    } catch (error, stackTrace) {
      // Keep the old list if there was one; just surface the error.
      state = AsyncError<List<SchoolModel>>(
        error,
        stackTrace,
      ).copyWithPrevious(state);

      return state.valueOrNull ?? [];
    }
  }

  // ----------------------------------------------------------------
  // Create School
  // ----------------------------------------------------------------
  // Doesn't touch the list while saving (so the dashboard behind the
  // create page doesn't flash). Reloads the list afterwards.

  Future<String?> createSchool(CreateSchoolRequest request) async {
    try {
      await ref.read(superAdminRepositoryProvider).createSchool(request);
    } catch (error) {
      return error.toString();
    }

    // The school was created — a failed reload shouldn't report failure.
    await getSchools();

    return null;
  }
}
