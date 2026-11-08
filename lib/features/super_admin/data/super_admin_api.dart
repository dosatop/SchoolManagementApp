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
import 'package:app/features/super_admin/models/school_people_models.dart';
import 'package:app/features/teacher/models/create_teacher_request.dart';
import 'package:app/features/teacher/models/teacher_model.dart';

class SuperAdminApi {
  final DioClient dioClient;

  SuperAdminApi(this.dioClient);

  String _school(String schoolId) => '/super-admin/schools/$schoolId';

  // ==================================================================
  // SCHOOLS
  // ==================================================================

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

  // ==================================================================
  // SCHOOL ADMINS
  // ==================================================================

  Future<Map<String, dynamic>> createSchoolAdmin(
    String schoolId,
    CreateSchoolAdminRequest request,
  ) async {
    final response = await dioClient.dio.post(
      '${_school(schoolId)}/admin',
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

  // ==================================================================
  // OLD SCHOOL ENDPOINTS (kept as they were)
  // ==================================================================

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

  // ==================================================================
  // SUPER ADMIN — SCHOOL TEACHERS / STUDENTS / CLASSES
  // ==================================================================
  // SuperAdminController (api/super-admin/schools/{schoolId}/...):
  //   GET/POST teachers · GET/POST students · GET/POST classes
  //   GET options (departments + trades for the Add student form)

  Future<List<SchoolTeacher>> getSchoolTeachers(String schoolId) async {
    final response = await dioClient.dio.get('${_school(schoolId)}/teachers');

    return parseList(response.data, 'teachers', SchoolTeacher.fromJson);
  }

  Future<List<SchoolStudent>> getSchoolStudents(
    String schoolId, {
    String? classId,
  }) async {
    final response = await dioClient.dio.get(
      '${_school(schoolId)}/students',
      queryParameters: classId == null ? null : {'classId': classId},
    );

    return parseList(response.data, 'students', SchoolStudent.fromJson);
  }

  Future<List<SchoolClass>> getSchoolClasses(String schoolId) async {
    final response = await dioClient.dio.get('${_school(schoolId)}/classes');

    return parseList(response.data, 'classes', SchoolClass.fromJson);
  }

  Future<SchoolFormOptions> getSchoolFormOptions(String schoolId) async {
    final response = await dioClient.dio.get('${_school(schoolId)}/options');

    return SchoolFormOptions.fromJson(response.data);
  }

  Future<void> createSchoolTeacher(
    String schoolId, {
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    await dioClient.dio.post(
      '${_school(schoolId)}/teachers',
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
      },
    );
  }

  Future<void> createSchoolStudent(
    String schoolId, {
    required String fullName,
    required String email,
    required String password,
    required String classId,
    String? phoneNumber,
    String? studentNumber,
    String? departmentId,
    String? tradeId,
    String? tradeSubjectId,
  }) async {
    await dioClient.dio.post(
      '${_school(schoolId)}/students',
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'classId': classId,
        'phoneNumber': phoneNumber,
        'studentNumber': studentNumber,
        'departmentId': departmentId,
        'tradeId': tradeId,
        'tradeSubjectId': tradeSubjectId,
      },
    );
  }

  Future<void> createSchoolClass(
    String schoolId, {
    required String name,
    int? level,
  }) async {
    await dioClient.dio.post(
      '${_school(schoolId)}/classes',
      data: {'name': name, 'level': level},
    );
  }

  // ==================================================================
  // SUPER ADMIN — EDIT / DELETE
  // ==================================================================

  Future<void> updateSchoolTeacher(
    String schoolId,
    String teacherId, {
    required String fullName,
    required String email,
    String? phoneNumber,
    String? newPassword,
  }) async {
    await dioClient.dio.put(
      '${_school(schoolId)}/teachers/$teacherId',
      data: {
        'fullName': fullName,
        'email': email,
        'phoneNumber': phoneNumber,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> deleteSchoolTeacher(String schoolId, String teacherId) async {
    await dioClient.dio.delete('${_school(schoolId)}/teachers/$teacherId');
  }

  Future<void> updateSchoolStudent(
    String schoolId,
    String studentId, {
    required String fullName,
    required String email,
    required String studentNumber,
    required String classId,
    String? phoneNumber,
    String? newPassword,
    String? departmentId,
    String? tradeId,
    String? tradeSubjectId,
  }) async {
    await dioClient.dio.put(
      '${_school(schoolId)}/students/$studentId',
      data: {
        'fullName': fullName,
        'email': email,
        'studentNumber': studentNumber,
        'classId': classId,
        'phoneNumber': phoneNumber,
        'newPassword': newPassword,
        'departmentId': departmentId,
        'tradeId': tradeId,
        'tradeSubjectId': tradeSubjectId,
      },
    );
  }

  Future<void> deleteSchoolStudent(String schoolId, String studentId) async {
    await dioClient.dio.delete('${_school(schoolId)}/students/$studentId');
  }

  Future<void> updateSchoolClass(
    String schoolId,
    String classId, {
    required String name,
  }) async {
    await dioClient.dio.put(
      '${_school(schoolId)}/classes/$classId',
      data: {'name': name},
    );
  }

  Future<void> deleteSchoolClass(String schoolId, String classId) async {
    await dioClient.dio.delete('${_school(schoolId)}/classes/$classId');
  }

  Future<void> removeClassTeacher(String schoolId, String classId) async {
    await dioClient.dio.delete(
      '${_school(schoolId)}/classes/$classId/class-teacher',
    );
  }

  // ==================================================================
  // SUPER ADMIN — SUBJECTS
  // ==================================================================

  Future<List<SchoolSubject>> getSchoolSubjects(String schoolId) async {
    final response = await dioClient.dio.get('${_school(schoolId)}/subjects');

    return parseList(response.data, 'subjects', SchoolSubject.fromJson);
  }

  Map<String, dynamic> _subjectBody({
    required String name,
    String? code,
    required int type,
    String? departmentId,
    String? tradeId,
  }) => {
    'name': name,
    'code': code,
    'type': type,
    // Only the matching link is sent (General → neither).
    'departmentId': type == SubjectTypes.department ? departmentId : null,
    'tradeId': type == SubjectTypes.trade ? tradeId : null,
  };

  Future<void> createSchoolSubject(
    String schoolId, {
    required String name,
    String? code,
    required int type,
    String? departmentId,
    String? tradeId,
  }) async {
    await dioClient.dio.post(
      '${_school(schoolId)}/subjects',
      data: _subjectBody(
        name: name,
        code: code,
        type: type,
        departmentId: departmentId,
        tradeId: tradeId,
      ),
    );
  }

  Future<void> updateSchoolSubject(
    String schoolId,
    String subjectId, {
    required String name,
    String? code,
    required int type,
    String? departmentId,
    String? tradeId,
  }) async {
    await dioClient.dio.put(
      '${_school(schoolId)}/subjects/$subjectId',
      data: _subjectBody(
        name: name,
        code: code,
        type: type,
        departmentId: departmentId,
        tradeId: tradeId,
      ),
    );
  }

  Future<void> deleteSchoolSubject(String schoolId, String subjectId) async {
    await dioClient.dio.delete('${_school(schoolId)}/subjects/$subjectId');
  }

  Future<void> assignSchoolSubject(
    String schoolId,
    String subjectId, {
    required List<String> classIds,
    String? teacherId,
  }) async {
    await dioClient.dio.post(
      '${_school(schoolId)}/subjects/$subjectId/classes',
      data: {'classIds': classIds, 'teacherId': teacherId},
    );
  }

  Future<void> removeSubjectFromClass(
    String schoolId,
    String subjectId,
    String classId,
  ) async {
    await dioClient.dio.delete(
      '${_school(schoolId)}/subjects/$subjectId/classes/$classId',
    );
  }
}