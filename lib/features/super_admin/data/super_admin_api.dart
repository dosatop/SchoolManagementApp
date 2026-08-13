import 'package:app/core/network/dio_client.dart';
import 'package:app/features/super_admin/models/create_school_admin_request.dart';
import 'package:app/features/super_admin/models/create_school_request.dart';
import 'package:app/features/super_admin/models/school_admin_model.dart';

class SuperAdminApi {
  final DioClient dioClient;

  SuperAdminApi(this.dioClient);

  Future<Map<String, dynamic>> createSchool(CreateSchoolRequest request) async {
    final response = await dioClient.dio.post(
      '/schools',
      data: request.toJson(),
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<List<dynamic>> getSchools() async {
    final response = await dioClient.dio.get('/schools');

    return List<dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> createSchoolAdmin(
    String schoolId,
    CreateSchoolAdminRequest request,
  ) async {
    final response = await dioClient.dio.post(
      '/superadmin/schools/$schoolId/admin',
      data: request.toJson(),
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<List<SchoolAdminModel>> getSchoolAdmins(String schoolId) async {
    final response = await dioClient.dio.get('/schools/$schoolId/admins');

    return (response.data as List)
        .map((json) => SchoolAdminModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
