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
import 'package:app/features/super_admin/models/school_people_models.dart';
import 'package:app/features/teacher/models/create_teacher_request.dart';
import 'package:app/features/teacher/models/teacher_model.dart';

class SuperAdminRepository {
  final SuperAdminApi api;

  SuperAdminRepository({required this.api});

  // ==================================================================
  // SCHOOLS
  // ==================================================================

  Future<Map<String, dynamic>> createSchool(CreateSchoolRequest request) {
    return api.createSchool(request);
  }

  Future<List<SchoolModel>> getSchools() async {
    final response = await api.getSchools();

    return response
        .map((json) => SchoolModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  // ==================================================================
  // SCHOOL ADMINS
  // ==================================================================

  Future<Map<String, dynamic>> createSchoolAdmin(
    String schoolId,
    CreateSchoolAdminRequest request,
  ) {
    return api.createSchoolAdmin(schoolId, request);
  }

  Future<List<SchoolAdminModel>> getSchoolAdmins(String schoolId) {
    return api.getSchoolAdmins(schoolId);
  }

  // ==================================================================
  // OLD SCHOOL ENDPOINTS (kept as they were)
  // ==================================================================

  Future<List<TeacherModel>> getTeachers(String schoolId) {
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

  // ==================================================================
  // SUPER ADMIN — SCHOOL TEACHERS / STUDENTS / CLASSES
  // ==================================================================

  Future<List<SchoolTeacher>> getSchoolTeachers(String schoolId) {
    return api.getSchoolTeachers(schoolId);
  }

  Future<List<SchoolStudent>> getSchoolStudents(
    String schoolId, {
    String? classId,
  }) {
    return api.getSchoolStudents(schoolId, classId: classId);
  }

  Future<List<SchoolClass>> getSchoolClasses(String schoolId) {
    return api.getSchoolClasses(schoolId);
  }

  Future<SchoolFormOptions> getSchoolFormOptions(String schoolId) {
    return api.getSchoolFormOptions(schoolId);
  }

  Future<void> createSchoolTeacher(
    String schoolId, {
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) {
    return api.createSchoolTeacher(
      schoolId,
      fullName: fullName,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
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
  }) {
    return api.createSchoolStudent(
      schoolId,
      fullName: fullName,
      email: email,
      password: password,
      classId: classId,
      phoneNumber: phoneNumber,
      studentNumber: studentNumber,
      departmentId: departmentId,
      tradeId: tradeId,
      tradeSubjectId: tradeSubjectId,
    );
  }

  Future<void> createSchoolClass(
    String schoolId, {
    required String name,
    int? level,
  }) {
    return api.createSchoolClass(schoolId, name: name, level: level);
  }
}
