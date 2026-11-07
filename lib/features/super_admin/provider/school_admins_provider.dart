import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:app/features/super_admin/models/create_school_admin_request.dart';
import 'package:app/features/super_admin/models/school_admin_model.dart';
import 'package:app/features/super_admin/provider/schools_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ====================================================================
// SCHOOL ADMINS (one list per school)
// ====================================================================

final schoolAdminsProvider =
    AsyncNotifierProvider.family<
      SchoolAdminsNotifier,
      List<SchoolAdminModel>,
      String
    >(SchoolAdminsNotifier.new);

class SchoolAdminsNotifier
    extends FamilyAsyncNotifier<List<SchoolAdminModel>, String> {
  // ----------------------------------------------------------------
  // Initial load
  // ----------------------------------------------------------------
  // Only a super admin ever calls this endpoint. Watching auth also
  // reloads the list automatically on login / logout.

  @override
  Future<List<SchoolAdminModel>> build(String schoolId) async {
    if (!signedInAs(ref, 'SuperAdmin')) return [];

    return ref.read(superAdminRepositoryProvider).getSchoolAdmins(schoolId);
  }

  // ----------------------------------------------------------------
  // Refresh
  // ----------------------------------------------------------------
  // Keeps the current list on screen while reloading.

  Future<void> refresh() async {
    state = const AsyncLoading<List<SchoolAdminModel>>().copyWithPrevious(
      state,
    );

    try {
      final admins = await ref
          .read(superAdminRepositoryProvider)
          .getSchoolAdmins(arg);

      state = AsyncData(admins);
    } catch (error, stackTrace) {
      state = AsyncError<List<SchoolAdminModel>>(
        error,
        stackTrace,
      ).copyWithPrevious(state);
    }
  }

  // ----------------------------------------------------------------
  // Create School Admin
  // ----------------------------------------------------------------
  // Returns null on success, or the server's message on failure.
  // Doesn't blank the list while saving; reloads it afterwards.

  Future<String?> createSchoolAdmin(CreateSchoolAdminRequest request) async {
    try {
      await ref
          .read(superAdminRepositoryProvider)
          .createSchoolAdmin(arg, request);
    } catch (error) {
      return schoolPeopleError(error);
    }

    // The admin was created — a failed reload shouldn't report failure.
    await refresh();

    return null;
  }
}
