import 'package:app/core/network/dio_client.dart';
import 'package:app/features/Classes/models/class_model.dart';
import 'package:app/features/Subjects/models/subject_model.dart';
import 'package:app/features/admin/models/admin_teacher_details_model.dart';
import 'package:app/features/admin/models/classes/admin_create_class_model.dart';
import 'package:app/features/admin/models/students/admin_class_model.dart';
import 'package:app/features/admin/models/students/admin_create_student_model.dart';
import 'package:app/features/admin/models/students/admin_student_model.dart';
import 'package:app/features/admin/models/subjects/admin_create_subject_model.dart';
import 'package:app/features/admin/models/subjects/admin_edit_subject_model.dart';
import 'package:app/features/admin/models/subjects/admin_subject_model.dart';

class AdminApi {
  final DioClient dioClient;

  AdminApi(this.dioClient);

  // ================================================================
  // TEACHERS
  // ================================================================

  // GET ALL TEACHERS
  Future<List<AdminTeacherModel>> getTeachers() async {
    final response = await dioClient.dio.get('/admin/teachers');

    final data = response.data as List;

    return data
        .map(
          (json) => AdminTeacherModel.fromJson(Map<String, dynamic>.from(json)),
        )
        .toList();
  }

  // ================================================================
  // CREATE TEACHER
  // ================================================================

  Future<AdminTeacherModel> createTeacher({
    required String schoolId,
    required Map<String, dynamic> data,
  }) async {
    final response = await dioClient.dio.post(
      '/schools/$schoolId/teachers',
      data: data,
    );

    return AdminTeacherModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  // ================================================================
  // UPDATE TEACHER
  // ================================================================

  Future<AdminTeacherModel> updateTeacher({
    required String schoolId,
    required String teacherId,
    required Map<String, dynamic> data,
  }) async {
    final response = await dioClient.dio.put(
      '/admin/schools/$schoolId/teachers/$teacherId',
      data: data,
    );

    return AdminTeacherModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  // ================================================================
  // DELETE TEACHER
  // ================================================================

  Future<void> deleteTeacher({
    required String schoolId,
    required String teacherId,
  }) async {
    await dioClient.dio.delete('/admin/schools/$schoolId/teachers/$teacherId');
  }

  // ================================================================
  // STUDENTS
  // ================================================================

  Future<List<AdminStudentModel>> getStudents() async {
    final response = await dioClient.dio.get('/admin/students');

    final data = response.data as List;

    return data
        .map(
          (json) => AdminStudentModel.fromJson(Map<String, dynamic>.from(json)),
        )
        .toList();
  }

  // ================================================================
  // CLASSES
  // ================================================================

  Future<List<AdminClassModel>> getClasses() async {
    final response = await dioClient.dio.get('/admin/classes');

    final data = response.data as List;

    return data
        .map(
          (json) => AdminClassModel.fromJson(Map<String, dynamic>.from(json)),
        )
        .toList();
  }

  // ================================================================
  // SUBJECTS
  // ================================================================

  Future<List<AdminSubjectModel>> getAdminSubjects() async {
    final response = await dioClient.dio.get('/admin/subjects');

    final data = response.data as List;

    return data
        .map(
          (json) => AdminSubjectModel.fromJson(Map<String, dynamic>.from(json)),
        )
        .toList();
  }

  Future<AdminSubjectModel> createSubject({
    required String schoolId,
    required AdminCreateSubjectModel data,
  }) async {
    final response = await dioClient.dio.post(
      '/schools/$schoolId/subjects',
      data: data.toJson(),
    );

    return AdminSubjectModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  // ================================================================
  // SUBJECT DETAILS
  // ================================================================

  Future<AdminSubjectModel> getSubjectById({
    required String schoolId,
    required String subjectId,
  }) async {
    final response = await dioClient.dio.get('/schools/$schoolId/subjects');

    final data = response.data as List;

    final subjectJson = data.firstWhere(
      (json) => json['subjectId'] == subjectId,
    );

    return AdminSubjectModel.fromJson(Map<String, dynamic>.from(subjectJson));
  }

  // ================================================================
  // ASSIGN TEACHER TO SUBJECT
  // ================================================================

  Future<void> assignTeacherToSubject({
    required String schoolId,
    required String teacherId,
    required String subjectId,
  }) async {
    await dioClient.dio.post(
      '/schools/$schoolId/teachers/$teacherId/subjects',
      data: {'subjectId': subjectId},
    );
  }

  // ================================================================
  // UNASSIGN TEACHER FROM SUBJECT
  // ================================================================

  Future<void> unassignTeacherFromSubject({
    required String schoolId,
    required String teacherId,
    required String subjectId,
  }) async {
    await dioClient.dio.delete(
      '/schools/$schoolId/teachers/$teacherId/subjects/$subjectId',
    );
  }

  // ================================================================
  // UPDATE SUBJECT
  // ================================================================

  Future<AdminSubjectModel> updateSubject({
    required String schoolId,
    required String subjectId,
    required AdminEditSubjectModel data,
  }) async {
    final response = await dioClient.dio.put(
      '/schools/$schoolId/subjects/$subjectId',
      data: data.toJson(),
    );

    return AdminSubjectModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  // ================================================================
  // DELETE SUBJECT
  // ================================================================

  Future<void> deleteSubject({
    required String schoolId,
    required String subjectId,
  }) async {
    await dioClient.dio.delete('/schools/$schoolId/subjects/$subjectId');
  }

  // ================================================================
  // GET MY SCHOOL CLASSES
  // ================================================================

  Future<List<ClassModel>> getMySchoolClasses() async {
    final response = await dioClient.dio.get('/schools/classes');

    final data = response.data as List;

    return data
        .map((json) => ClassModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  // ================================================================
  // CREATE CLASS
  // ================================================================

  // ================================================================
  // CREATE CLASS
  // ================================================================

  Future<AdminClassModel> createClass({
    required String schoolId,
    required AdminCreateClassModel data,
  }) async {
    final response = await dioClient.dio.post(
      '/schools/$schoolId/classes',
      data: data.toJson(),
    );

    return AdminClassModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  // ================================================================
  // CREATE STUDENT
  // ================================================================

  // Future<AdminStudentModel> createStudent({
  //   required AdminCreateStudentModel data,
  // }) async {
  //   final response = await dioClient.dio.post(
  //     '/schools/students',
  //     data: data,
  //   );

  //   return AdminStudentModel.fromJson(
  //     Map<String, dynamic>.from(response.data),
  //   );
  // }

  Future<AdminStudentModel> createStudent({
    required String schoolId,
    required AdminCreateStudentModel data,
  }) async {
    final response = await dioClient.dio.post(
      '/schools/$schoolId/students',
      data: data.toJson(),
    );

    return AdminStudentModel.fromJson(Map<String, dynamic>.from(response.data));
  }
}
