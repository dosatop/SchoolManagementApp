import 'package:app/features/super_admin/data/super_admin_api.dart';
import 'package:app/features/super_admin/models/create_school_admin_request.dart';
import 'package:app/features/super_admin/models/create_school_request.dart';
import 'package:app/features/super_admin/models/school_admin_model.dart';
import 'package:app/features/super_admin/models/school_model.dart';

class SuperAdminRepository {
  final SuperAdminApi api;

  SuperAdminRepository({required this.api});

  Future<Map<String, dynamic>> createSchool(CreateSchoolRequest request) {
    return api.createSchool(request);
  }

  Future<List<SchoolModel>> getSchools() async {
    final response = await api.getSchools();

    return response
        .map((json) => SchoolModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<Map<String, dynamic>> createSchoolAdmin(
    String schoolId,
    CreateSchoolAdminRequest request,
  ) async {
    return await api.createSchoolAdmin(schoolId, request);
  }

  Future<List<SchoolAdminModel>> getSchoolAdmins(String schoolId) async {
    return await api.getSchoolAdmins(schoolId);
  }
}
