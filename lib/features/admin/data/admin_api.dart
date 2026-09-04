import 'package:app/core/Errors/custom_exception_error.dart';
import 'package:app/core/network/dio_client.dart';

import 'package:app/features/Classes/models/class_model.dart';

import 'package:app/features/admin/models/academic_session/current_academic_session_model.dart';

import 'package:app/features/admin/models/admin_teacher_details_model.dart';

import 'package:app/features/admin/models/attendance/admin_attendance_model.dart';
import 'package:app/features/admin/models/classes/admin_assign_class_subject_request.dart';

import 'package:app/features/admin/models/classes/admin_create_class_model.dart';
import 'package:app/features/admin/models/classes/admin_get_class_subjects_model.dart';
import 'package:app/features/admin/models/parents/admin_parent_child_model.dart';

import 'package:app/features/admin/models/parents/admin_parent_model.dart';

import 'package:app/features/admin/models/results/admin_result_model.dart';

import 'package:app/features/admin/models/classes/admin_class_model.dart';
import 'package:app/features/admin/models/students/admin_create_student_model.dart';
import 'package:app/features/admin/models/students/admin_department_model.dart';
import 'package:app/features/admin/models/students/admin_edit_student_model.dart';
import 'package:app/features/admin/models/students/admin_student_detail_model.dart';
import 'package:app/features/admin/models/students/admin_student_model.dart';

import 'package:app/features/admin/models/subjects/admin_create_subject_model.dart'
    hide AdminClassSubjectModel;
import 'package:app/features/admin/models/subjects/admin_edit_subject_model.dart';
import 'package:app/features/admin/models/subjects/admin_subject_model.dart';
import 'package:app/features/admin/models/subjects/admin_trade_model.dart';

import 'package:dio/dio.dart';

class AdminApi {
  final DioClient dioClient;

  AdminApi(this.dioClient);

  // ================================================================
  // TEACHERS
  // ================================================================

  Future<List<AdminTeacherModel>> getTeachers() async {
    try {
      final response = await dioClient.dio.get('/admin/teachers');

      final data = response.data as List;

      return data
          .map(
            (json) =>
                AdminTeacherModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // GET TEACHER DETAILS
  // ================================================================

  Future<AdminTeacherModel> getTeacherDetails({
    required String teacherId,
  }) async {
    try {
      final response = await dioClient.dio.get('/admin/teachers/$teacherId');

      return AdminTeacherModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // CREATE TEACHER
  // ================================================================

  Future<AdminTeacherModel> createTeacher({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await dioClient.dio.post('/admin/teachers', data: data);

      return AdminTeacherModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // UPDATE TEACHER
  // ================================================================

  Future<AdminTeacherModel> updateTeacher({
    required String teacherId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await dioClient.dio.put(
        '/admin/teachers/$teacherId',
        data: data,
      );

      return AdminTeacherModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // DELETE TEACHER
  // ================================================================

  Future<void> deleteTeacher({required String teacherId}) async {
    try {
      await dioClient.dio.delete('/admin/teachers/$teacherId');
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // STUDENTS
  // ================================================================

  Future<List<AdminStudentModel>> getStudents() async {
    try {
      final response = await dioClient.dio.get('/admin/students');

      final data = Map<String, dynamic>.from(response.data as Map);

      final students = data['students'] as List<dynamic>? ?? [];

      return students
          .map(
            (json) => AdminStudentModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // STUDENT DETAILS
  // ================================================================

  Future<AdminStudentDetailModel> getStudentDetails({
    required String studentId,
  }) async {
    try {
      final response = await dioClient.dio.get(
        '/admin/students/$studentId/records',
      );

      return AdminStudentDetailModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // CREATE STUDENT
  // ================================================================

  Future<AdminStudentModel> createStudent({
    required String schoolId,
    required AdminCreateStudentModel data,
  }) async {
    try {
      final response = await dioClient.dio.post(
        '/admin/students',
        data: data.toJson(),
      );

      return AdminStudentModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // UPDATE STUDENT
  // ================================================================

  Future<AdminStudentModel> updateStudent({
    required String studentId,
    required AdminEditStudentModel data,
  }) async {
    try {
      final response = await dioClient.dio.put(
        '/admin/students/$studentId',
        data: data.toJson(),
      );

      return AdminStudentModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // DELETE STUDENT
  // ================================================================

  Future<void> deleteStudent({required String studentId}) async {
    try {
      await dioClient.dio.delete('/admin/students/$studentId');
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // CLASSES
  // ================================================================

  Future<List<AdminClassModel>> getClasses() async {
    try {
      final response = await dioClient.dio.get('/admin/classes');

      final data = response.data as List;

      return data
          .map(
            (json) => AdminClassModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // CREATE CLASS
  // ================================================================

  Future<AdminClassModel> createClass({
    required String schoolId,
    required AdminCreateClassModel data,
  }) async {
    try {
      final response = await dioClient.dio.post(
        '/schools/$schoolId/classes',
        data: data.toJson(),
      );

      return AdminClassModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // GET MY SCHOOL CLASSES
  // ================================================================

  Future<List<ClassModel>> getMySchoolClasses() async {
    try {
      final response = await dioClient.dio.get('/schools/classes');

      final data = response.data as List;

      return data
          .map((json) => ClassModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  Future<AdminClassSubjectModel> assignSubjectToClass({
    required AdminAssignClassSubjectRequest data,
  }) async {
    try {
      final response = await dioClient.dio.post(
        '/admin/classes/subjects',
        data: data.toJson(),
      );

      return AdminClassSubjectModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // GET ADMIN CLASS SUBJECTS
  Future<List<AdminGetClassSubjectModel>> getAdminClassSubjects({
    required String classId,
  }) async {
    try {
      final response = await dioClient.dio.get('/admin/class/$classId');

      final data = response.data as List;

      return data
          .map(
            (json) => AdminGetClassSubjectModel.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  Future<void> unassignSubjectFromClass({
    required String classId,
    required String subjectId,
  }) async {
    try {
      await dioClient.dio.delete('/admin/class/$classId/subject/$subjectId');
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  Future<AdminClassModel> assignClassTeacher({
    required String classId,
    required String teacherId,
  }) async {
    try {
      final response = await dioClient.dio.post(
        '/admin/classes/$classId/class-teacher/$teacherId',
      );

      return AdminClassModel.fromJson(Map<String, dynamic>.from(response.data));
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // SUBJECTS
  // ================================================================

  Future<List<AdminSubjectModel>> getAdminSubjects() async {
    try {
      final response = await dioClient.dio.get('/admin/subjects');

      final data = response.data as List;

      return data
          .map(
            (json) =>
                AdminSubjectModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // CREATE SUBJECT
  // ================================================================

  Future<AdminSubjectModel> createSubject({
    required String schoolId,
    required AdminCreateSubjectModel data,
  }) async {
    try {
      final response = await dioClient.dio.post(
        '/schools/$schoolId/subjects',
        data: data.toJson(),
      );

      return AdminSubjectModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // GET SUBJECT BY ID
  // ================================================================

  Future<AdminSubjectModel> getSubjectById({
    required String schoolId,
    required String subjectId,
  }) async {
    try {
      final response = await dioClient.dio.get('/schools/$schoolId/subjects');

      final data = response.data as List;

      final subjectJson = data.firstWhere(
        (json) => json['subjectId'] == subjectId,
      );

      return AdminSubjectModel.fromJson(Map<String, dynamic>.from(subjectJson));
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // UPDATE SUBJECT
  // ================================================================

  Future<AdminSubjectModel> updateSubject({
    required String schoolId,
    required String subjectId,
    required AdminEditSubjectModel data,
  }) async {
    try {
      final response = await dioClient.dio.put(
        '/schools/$schoolId/subjects/$subjectId',
        data: data.toJson(),
      );

      return AdminSubjectModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // DELETE SUBJECT
  // ================================================================

  Future<void> deleteSubject({
    required String schoolId,
    required String subjectId,
  }) async {
    try {
      await dioClient.dio.delete('/schools/$schoolId/subjects/$subjectId');
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // ASSIGN TEACHER TO SUBJECT
  // ================================================================

  Future<void> assignTeacherToSubject({
    required String teacherId,
    required String subjectId,
    required String classId,
  }) async {
    try {
      await dioClient.dio.post(
        '/admin/teachers/$teacherId/teaching-assignments',
        data: {'subjectId': subjectId, 'classId': classId},
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // GET TEACHERS ASSIGNED TO SUBJECT
  // ================================================================

  Future<List<AdminSubjectTeacherModel>> getTeachersForSubject({
    required String subjectId,
  }) async {
    try {
      final response = await dioClient.dio.get('/admin/$subjectId/teachers');

      final data = response.data as List;

      return data
          .map(
            (json) => AdminSubjectTeacherModel.fromJson(
              Map<String, dynamic>.from(json),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // UNASSIGN TEACHER FROM SUBJECT
  // ================================================================

  Future<void> unassignTeacherFromSubject({
    required String assignmentId,
  }) async {
    try {
      await dioClient.dio.delete('/admin/teaching-subjects/$assignmentId');
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // PARENTS
  // ================================================================

  Future<List<AdminParentModel>> getParents() async {
    try {
      final response = await dioClient.dio.get('/admin/parents');

      final data = response.data as List;

      return data
          .map(
            (json) =>
                AdminParentModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // GET PARENT DETAILS
  // ================================================================

  Future<AdminParentDetailModel> getParentDetails({
    required String parentId,
  }) async {
    try {
      final response = await dioClient.dio.get('/admin/parents/$parentId');

      return AdminParentDetailModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // UPDATE PARENT
  // ================================================================

  Future<AdminParentModel> updateParent({
    required String parentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await dioClient.dio.put(
        '/admin/parents/$parentId',
        data: data,
      );

      return AdminParentModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // DELETE PARENT
  // ================================================================

  Future<void> deleteParent({required String parentId}) async {
    try {
      await dioClient.dio.delete('/admin/parents/$parentId');
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // DEPARTMENTS
  // ================================================================

  Future<List<AdminDepartmentModel>> getDepartments() async {
    try {
      final response = await dioClient.dio.get('/admin/departments');

      final data = Map<String, dynamic>.from(response.data as Map);

      final departments = data['data'] as List<dynamic>? ?? [];

      return departments
          .map(
            (json) => AdminDepartmentModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // TRADES
  // ================================================================

  Future<List<AdminTradeModel>> getTrades() async {
    try {
      final response = await dioClient.dio.get('/admin/trades');

      final data = response.data as List;

      return data
          .map(
            (json) => AdminTradeModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // STUDENT ATTENDANCE
  // ================================================================

  Future<AdminStudentAttendanceModel> getStudentAttendance({
    required String studentId,
    required String session,
    required String term,
  }) async {
    try {
      final response = await dioClient.dio.get(
        '/admin/students/$studentId/attendance',
        queryParameters: {'session': session, 'term': term},
      );

      return AdminStudentAttendanceModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // GET RESULTS FOR SCHOOL
  // ================================================================

  Future<AdminResultsResponse> getResultsForSchool({
    required String schoolId,
    String? session,
    String? term,
  }) async {
    try {
      final response = await dioClient.dio.get(
        '/admin/results',
        queryParameters: {
          'schoolId': schoolId,
          if (session != null && session.isNotEmpty) 'session': session,
          if (term != null && term.isNotEmpty) 'term': term,
        },
      );

      return AdminResultsResponse.fromJson(response.data);
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // CREATE RESULT
  // ================================================================

  Future<AdminResultModel> createResult(
    CreateAdminResultRequest request,
  ) async {
    try {
      final response = await dioClient.dio.post(
        '/admin/results',
        data: request.toJson(),
      );

      return AdminResultModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // CREATE TEST RESULT
  // ================================================================

  Future<AdminResultModel> createTestResult(
    CreateAdminResultRequest request,
  ) async {
    try {
      final response = await dioClient.dio.post(
        '/admin/results/test',
        data: request.toJson(),
      );

      return AdminResultModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // CREATE EXAM RESULT
  // ================================================================

  Future<AdminResultModel> createExamResult(
    CreateAdminResultRequest request,
  ) async {
    try {
      final response = await dioClient.dio.post(
        '/admin/results/exam',
        data: request.toJson(),
      );

      return AdminResultModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // GET RESULT
  // ================================================================

  Future<AdminResultModel> getResult({required String resultId}) async {
    try {
      final response = await dioClient.dio.get('/admin/results/$resultId');

      return AdminResultModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // GET STUDENT RESULTS
  // ================================================================

  Future<AdminResultsResponse> getStudentResults({
    required String studentId,
    required String session,
    required String term,
  }) async {
    try {
      final response = await dioClient.dio.get(
        '/admin/students/$studentId/results',
        queryParameters: {'session': session, 'term': term},
      );

      return AdminResultsResponse.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // GET CLASS RESULTS
  // ================================================================

  Future<AdminResultsResponse> getClassResults({
    required String classId,
    required String session,
    required String term,
  }) async {
    try {
      final response = await dioClient.dio.get(
        '/admin/classes/$classId/results',
        queryParameters: {'session': session, 'term': term},
      );

      return AdminResultsResponse.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // GET SUBJECT RESULTS
  // ================================================================

  Future<AdminResultsResponse> getSubjectResults({
    required String subjectId,
    required String classId,
    required String session,
    required String term,
  }) async {
    try {
      final response = await dioClient.dio.get(
        '/admin/subjects/$subjectId/results',
        queryParameters: {'classId': classId, 'session': session, 'term': term},
      );

      return AdminResultsResponse.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // UPDATE RESULT
  // ================================================================

  Future<AdminResultModel> updateResult({
    required String resultId,
    required UpdateAdminResultRequest request,
  }) async {
    try {
      final response = await dioClient.dio.put(
        '/admin/results/$resultId',
        data: request.toJson(),
      );

      return AdminResultModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // DELETE RESULT
  // ================================================================

  Future<void> deleteResult({required String resultId}) async {
    try {
      await dioClient.dio.delete('/admin/results/$resultId');
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // CURRENT ACADEMIC SESSION
  // ================================================================

  Future<CurrentAcademicSessionModel> getCurrentAcademicSession({
    required String schoolId,
  }) async {
    try {
      final response = await dioClient.dio.get(
        '/academic-sessions/current',
        queryParameters: {'schoolId': schoolId},
      );

      return CurrentAcademicSessionModel.fromJson(
        Map<String, dynamic>.from(response.data),
      );
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }
}
