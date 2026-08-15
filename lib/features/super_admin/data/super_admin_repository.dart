import 'package:app/features/Classes/models/class_model.dart';
import 'package:app/features/Classes/models/create_class_request.dart';
import 'package:app/features/Subjects/models/create_subject_request.dart';
import 'package:app/features/Subjects/models/subject_model.dart';
import 'package:app/features/students/models/create_student_request.dart';
import 'package:app/features/students/models/student_model.dart';
import 'package:app/features/super_admin/data/super_admin_api.dart';
import 'package:app/features/super_admin/models/create_school_admin_request.dart';
import 'package:app/features/super_admin/models/create_school_request.dart';
import 'package:app/features/super_admin/models/school_admin_model.dart';
import 'package:app/features/super_admin/models/school_model.dart';
import 'package:app/features/teacher/models/create_teacher_request.dart';
import 'package:app/features/teacher/models/teacher_model.dart';

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

  Future<List<TeacherModel>> getTeachers(String schoolId) async {
    return api.getTeachers(schoolId);
  }

  Future<List<ClassModel>> getClasses(String schoolId) {
    return api.getClasses(schoolId);
  }

  Future<List<StudentModel>> getStudents(String schoolId) {
    return api.getStudents(schoolId);
  }

  Future<List<SubjectModel>> getSubjects(String schoolId) {
    return api.getSubjects(schoolId);
  }

  Future<Map<String, dynamic>> createClass(
    String schoolId,
    CreateClassRequest request,
  ) {
    return api.createClass(schoolId, request);
  }

  Future<Map<String, dynamic>> createTeacher(
    String schoolId,
    CreateTeacherRequest request,
  ) {
    return api.createTeacher(schoolId, request);
  }

  Future<Map<String, dynamic>> createStudent(
    String schoolId,
    CreateStudentRequest request,
  ) {
    return api.createStudent(schoolId, request);
  }

  Future<Map<String, dynamic>> createSubject(
    String schoolId,
    CreateSubjectRequest request,
  ) {
    return api.createSubject(schoolId, request);
  }
}
