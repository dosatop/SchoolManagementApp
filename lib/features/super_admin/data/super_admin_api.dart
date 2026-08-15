import 'package:app/core/network/dio_client.dart';
import 'package:app/features/Classes/models/class_model.dart';
import 'package:app/features/Classes/models/create_class_request.dart';
import 'package:app/features/Subjects/models/create_subject_request.dart';
import 'package:app/features/Subjects/models/subject_model.dart';
import 'package:app/features/students/models/create_student_request.dart';
import 'package:app/features/students/models/student_model.dart';
import 'package:app/features/super_admin/models/create_school_admin_request.dart';
import 'package:app/features/super_admin/models/create_school_request.dart';
import 'package:app/features/super_admin/models/school_admin_model.dart';
import 'package:app/features/teacher/models/create_teacher_request.dart';
import 'package:app/features/teacher/models/teacher_model.dart';

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
      '/super-admin/schools/$schoolId/admin',
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

  Future<List<TeacherModel>> getTeachers(String schoolId) async {
    final response = await dioClient.dio.get('/schools/$schoolId/teachers');

    final data = response.data as List;

    return data
        .map((json) => TeacherModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  Future<List<ClassModel>> getClasses(String schoolId) async {
    final response = await dioClient.dio.get('/schools/$schoolId/classes');

    final data = response.data as List;

    return data
        .map((json) => ClassModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<StudentModel>> getStudents(String schoolId) async {
    final response = await dioClient.dio.get('/schools/$schoolId/students');

    final data = response.data as List;

    return data
        .map((json) => StudentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<SubjectModel>> getSubjects(String schoolId) async {
    final response = await dioClient.dio.get('/schools/$schoolId/subjects');

    final data = response.data as List;

    return data
        .map((json) => SubjectModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> createClass(
    String schoolId,
    CreateClassRequest request,
  ) async {
    final response = await dioClient.dio.post(
      '/schools/$schoolId/classes',
      data: request.toJson(),
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> createTeacher(
    String schoolId,
    CreateTeacherRequest request,
  ) async {
    final response = await dioClient.dio.post(
      '/schools/$schoolId/teachers',
      data: request.toJson(),
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> createStudent(
    String schoolId,
    CreateStudentRequest request,
  ) async {
    final response = await dioClient.dio.post(
      '/schools/$schoolId/students',
      data: request.toJson(),
    );

    return Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> createSubject(
  String schoolId,
  CreateSubjectRequest request,
) async {
  final response = await dioClient.dio.post(
    '/schools/$schoolId/subjects',
    data: request.toJson(),
  );

  return Map<String, dynamic>.from(response.data);
}
}
