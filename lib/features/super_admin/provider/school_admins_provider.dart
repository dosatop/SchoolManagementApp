import 'package:app/features/super_admin/models/create_school_admin_request.dart';
import 'package:app/features/super_admin/models/school_admin_model.dart';
import 'package:app/features/super_admin/provider/schools_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final schoolAdminsProvider =
    AsyncNotifierProvider.family<
      SchoolAdminsNotifier,
      List<SchoolAdminModel>,
      String
    >(SchoolAdminsNotifier.new);

class SchoolAdminsNotifier
    extends FamilyAsyncNotifier<List<SchoolAdminModel>, String> {
  @override
  Future<List<SchoolAdminModel>> build(String schoolId) async {
    final repository = ref.read(superAdminRepositoryProvider);

    return repository.getSchoolAdmins(schoolId);
  }

  Future<String?> createSchoolAdmin(CreateSchoolAdminRequest request) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(superAdminRepositoryProvider);

      await repository.createSchoolAdmin(arg, request);

      final admins = await repository.getSchoolAdmins(arg);

      state = AsyncData(admins);

      return null;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return error.toString();
    }
  }
}
