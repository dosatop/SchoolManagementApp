import 'package:app/core/network/dio_provider.dart';
import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:app/features/super_admin/data/super_admin_api.dart';
import 'package:app/features/super_admin/data/super_admin_repository.dart';
import 'package:app/features/super_admin/models/create_school_request.dart';
import 'package:app/features/super_admin/models/school_model.dart';
import 'package:app/features/super_admin/models/school_people_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ====================================================================
// REPOSITORY
// ====================================================================

final superAdminRepositoryProvider = Provider<SuperAdminRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);

  final api = SuperAdminApi(dioClient);

  return SuperAdminRepository(api: api);
});

// ====================================================================
// SCHOOLS
// ====================================================================

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
      return schoolPeopleError(error);
    }

    // The school was created — a failed reload shouldn't report failure.
    await getSchools();

    return null;
  }
}

// ====================================================================
// SCHOOL TEACHERS / STUDENTS / CLASSES
// ====================================================================
// One per school, auto-disposed when the page closes.
// Guarded: never calls the API unless signed in as SuperAdmin.

final schoolTeachersProvider = FutureProvider.autoDispose
    .family<List<SchoolTeacher>, String>((ref, schoolId) async {
      if (!signedInAs(ref, 'SuperAdmin')) return const [];
      return ref.read(superAdminRepositoryProvider).getSchoolTeachers(schoolId);
    });

final schoolStudentsProvider = FutureProvider.autoDispose
    .family<List<SchoolStudent>, String>((ref, schoolId) async {
      if (!signedInAs(ref, 'SuperAdmin')) return const [];
      return ref.read(superAdminRepositoryProvider).getSchoolStudents(schoolId);
    });

final schoolClassesProvider = FutureProvider.autoDispose
    .family<List<SchoolClass>, String>((ref, schoolId) async {
      if (!signedInAs(ref, 'SuperAdmin')) return const [];
      return ref.read(superAdminRepositoryProvider).getSchoolClasses(schoolId);
    });

// ====================================================================
// FRIENDLY ERROR
// ====================================================================
// Turns a Dio error into the server's message (e.g. "Email already
// exists") instead of the long DioException text.

String schoolPeopleError(Object error) {
  try {
    final data = (error as dynamic).response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['Message'];
      if (message != null && '$message'.trim().isNotEmpty) return '$message';
    }
    final status = (error as dynamic).response?.statusCode;
    if (status == 404) {
      return 'This list is not available yet. Make sure the server has '
          'the school people endpoints.';
    }
    if (status == 403) return "You don't have permission to view this.";
  } catch (_) {}

  final text = error.toString().replaceFirst('Exception: ', '').trim();
  if (text.isEmpty || text.contains('DioException')) {
    return 'Something went wrong. Check your connection and try again.';
  }
  return text;
}