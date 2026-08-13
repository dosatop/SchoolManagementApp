import 'package:app/core/network/dio_provider.dart';
import 'package:app/features/super_admin/data/super_admin_api.dart';
import 'package:app/features/super_admin/data/super_admin_repository.dart';
import 'package:app/features/super_admin/models/create_school_admin_request.dart';
import 'package:app/features/super_admin/models/create_school_request.dart';
import 'package:app/features/super_admin/models/school_admin_model.dart';
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
  @override
  Future<List<SchoolModel>> build() async {
    return [];
  }

  // -------------------------
  // Get Schools
  // -------------------------

  Future<List<SchoolModel>> getSchools() async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(superAdminRepositoryProvider);

      final schools = await repository.getSchools();

      state = AsyncData(schools);

      return schools;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return [];
    }
  }

  // -------------------------
  // Create School
  // -------------------------

  Future<String?> createSchool(CreateSchoolRequest request) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(superAdminRepositoryProvider);

      await repository.createSchool(request);

      // Reload schools after creating one
      final schools = await repository.getSchools();

      state = AsyncData(schools);

      return null;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return error.toString();
    }
  }

  // // -------------------------
  // // Create School Admin
  // // -------------------------

  // Future<String?> createSchoolAdmin(
  //   String schoolId,
  //   CreateSchoolAdminRequest request,
  // ) async {
  //   state = const AsyncLoading();

  //   try {
  //     final repository = ref.read(superAdminRepositoryProvider);

  //     await repository.createSchoolAdmin(schoolId, request);

  //     // Don't destroy the school list after creating admin.
  //     // Reload it instead.
  //     final schools = await repository.getSchools();

  //     state = AsyncData(schools);

  //     return null;
  //   } catch (error, stackTrace) {
  //     state = AsyncError(error, stackTrace);

  //     return error.toString();
  //   }
  // }

  // Future<List<SchoolAdminModel>> getSchoolAdmins(String schoolId) async {
  //   state = const AsyncLoading();

  //   try {
  //     final repository = ref.read(superAdminRepositoryProvider);

  //     final admins = await repository.getSchoolAdmins(schoolId);

  //     // state = AsyncData(admins);

  //     return admins;
  //   } catch (error, stackTrace) {
  //     state = AsyncError(error, stackTrace);

  //     return [];
  //   }
  // }
}
