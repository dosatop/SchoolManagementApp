import 'package:app/core/Errors/custom_exception_error.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:dio/dio.dart';

class TeacherApi {
  final DioClient dioClient;

  TeacherApi(this.dioClient);

  // ================================================================
  // TEACHER PROFILE
  // ================================================================

  Future<dynamic> getTeacherProfile() async {
    try {
      final response = await dioClient.dio.get('/teacher/profile');

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // TEACHER CLASSES
  // ================================================================

  Future<dynamic> getTeacherClasses() async {
    try {
      final response = await dioClient.dio.get('/teacher/classes');

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // TEACHER SUBJECTS
  // ================================================================

  Future<dynamic> getTeacherSubjects() async {
    try {
      final response = await dioClient.dio.get('/teacher/subjects');

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // TEACHER STUDENTS
  // ================================================================

  Future<dynamic> getTeacherStudents({String? classId}) async {
    try {
      final response = await dioClient.dio.get(
        '/teacher/students',
        queryParameters: {
          if (classId != null && classId.isNotEmpty) 'classId': classId,
        },
      );

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // GET TEACHER STUDENT DETAILS
  // ================================================================

  Future<dynamic> getStudentDetails({required String studentId}) async {
    final response = await dioClient.dio.get('/teacher/students/$studentId');

    return response.data;
  }

  // ================================================================
  // TEACHER RESULTS
  // ================================================================

  Future<dynamic> getTeacherResults({
    String? studentId,
    String? classId,
    String? subjectId,
    String? session,
    String? term,
  }) async {
    try {
      final response = await dioClient.dio.get(
        '/teacher/results',
        queryParameters: {
          if (studentId != null) 'studentId': studentId,
          if (classId != null) 'classId': classId,
          if (subjectId != null) 'subjectId': subjectId,
          if (session != null) 'session': session,
          if (term != null) 'term': term,
        },
      );

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // UPLOAD TEST RESULT
  // ================================================================

  Future<dynamic> uploadTestResult({
    required String studentId,
    required String classId,
    required String subjectId,
    required double testScore,
    String? remark,
  }) async {
    try {
      final response = await dioClient.dio.post(
        '/teacher/results/test',
        data: {
          'studentId': studentId,
          'classId': classId,
          'subjectId': subjectId,
          'testScore': testScore,
          if (remark != null) 'remark': remark,
        },
      );

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // UPLOAD EXAM RESULT
  // ================================================================

  Future<dynamic> uploadExamResult({
    required String studentId,
    required String classId,
    required String subjectId,
    required double examScore,
    String? remark,
  }) async {
    try {
      final response = await dioClient.dio.post(
        '/teacher/results/exam',
        data: {
          'studentId': studentId,
          'classId': classId,
          'subjectId': subjectId,
          'examScore': examScore,
          if (remark != null) 'remark': remark,
        },
      );

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // UPLOAD COMPLETE RESULT
  // ================================================================

  Future<dynamic> uploadResult({
    required String studentId,
    required String classId,
    required String subjectId,
    required double testScore,
    required double examScore,
    String? remark,
  }) async {
    try {
      final response = await dioClient.dio.post(
        '/teacher/results',
        data: {
          'studentId': studentId,
          'classId': classId,
          'subjectId': subjectId,
          'testScore': testScore,
          'examScore': examScore,
          if (remark != null) 'remark': remark,
        },
      );

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // BULK RESULTS (whole class, one subject)
  // ================================================================
  // POST /teacher/results/bulk        → test + exam per student
  // POST /teacher/results/bulk/test   → test only (keeps saved exam)
  // POST /teacher/results/bulk/exam   → exam only (keeps saved test)
  //
  // results: [{ studentId, testScore?, examScore?, remark? }]
  // The server uses the current session/term and updates existing
  // results instead of duplicating them.

  Future<dynamic> bulkResults({
    required String classId,
    required String subjectId,
    required List<Map<String, dynamic>> results,
  }) => _bulk('/teacher/results/bulk', classId, subjectId, results);

  Future<dynamic> bulkTestResults({
    required String classId,
    required String subjectId,
    required List<Map<String, dynamic>> results,
  }) => _bulk('/teacher/results/bulk/test', classId, subjectId, results);

  Future<dynamic> bulkExamResults({
    required String classId,
    required String subjectId,
    required List<Map<String, dynamic>> results,
  }) => _bulk('/teacher/results/bulk/exam', classId, subjectId, results);

  Future<dynamic> _bulk(
    String path,
    String classId,
    String subjectId,
    List<Map<String, dynamic>> results,
  ) async {
    try {
      final response = await dioClient.dio.post(
        path,
        data: {
          'classId': classId,
          'subjectId': subjectId,
          'results': results,
        },
      );

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // UPDATE TEST RESULT
  // ================================================================

  Future<dynamic> updateTestResult({
    required String resultId,
    required double testScore,
    String? remark,
  }) async {
    try {
      final response = await dioClient.dio.put(
        '/teacher/results/$resultId/test',
        data: {'testScore': testScore, if (remark != null) 'remark': remark},
      );

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // UPDATE EXAM RESULT
  // ================================================================

  Future<dynamic> updateExamResult({
    required String resultId,
    required double examScore,
    String? remark,
  }) async {
    try {
      final response = await dioClient.dio.put(
        '/teacher/results/$resultId/exam',
        data: {'examScore': examScore, if (remark != null) 'remark': remark},
      );

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // UPDATE COMPLETE RESULT
  // ================================================================

  Future<dynamic> updateResult({
    required String resultId,
    required double testScore,
    required double examScore,
    String? remark,
  }) async {
    try {
      final response = await dioClient.dio.put(
        '/teacher/results/$resultId',
        data: {
          'testScore': testScore,
          'examScore': examScore,
          if (remark != null) 'remark': remark,
        },
      );

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // CREATE ASSIGNMENT
  // ================================================================

  Future<dynamic> createAssignment({
    required String classId,
    required String subjectId,
    required String title,
    String? description,
    String? attachmentUrl,
    String? dueDate,
  }) async {
    try {
      final response = await dioClient.dio.post(
        '/teacher/assignments',
        data: {
          'classId': classId,
          'subjectId': subjectId,
          'title': title,
          if (description != null) 'description': description,
          if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
          if (dueDate != null) 'dueDate': dueDate,
        },
      );

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // GET ASSIGNMENTS
  // ================================================================

  Future<dynamic> getAssignments({
    String? classId,
    String? subjectId,
    String? session,
    String? term,
  }) async {
    try {
      final response = await dioClient.dio.get(
        '/teacher/assignments',
        queryParameters: {
          if (classId != null) 'classId': classId,
          if (subjectId != null) 'subjectId': subjectId,
          if (session != null) 'session': session,
          if (term != null) 'term': term,
        },
      );

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // GET SINGLE ASSIGNMENT
  // ================================================================

  Future<dynamic> getAssignment({required String assignmentId}) async {
    try {
      final response = await dioClient.dio.get(
        '/teacher/assignments/$assignmentId',
      );

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // UPDATE ASSIGNMENT
  // ================================================================

  Future<dynamic> updateAssignment({
    required String assignmentId,
    required String classId,
    required String subjectId,
    required String title,
    String? description,
    String? attachmentUrl,
    String? dueDate,
    required bool isPublished,
  }) async {
    try {
      final response = await dioClient.dio.put(
        '/teacher/assignments/$assignmentId',
        data: {
          'classId': classId,
          'subjectId': subjectId,
          'title': title,
          if (description != null) 'description': description,
          if (attachmentUrl != null) 'attachmentUrl': attachmentUrl,
          if (dueDate != null) 'dueDate': dueDate,
          'isPublished': isPublished,
        },
      );

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // DELETE ASSIGNMENT
  // ================================================================

  Future<void> deleteAssignment({required String assignmentId}) async {
    try {
      await dioClient.dio.delete('/teacher/assignments/$assignmentId');
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // CREATE ATTENDANCE
  // ================================================================

  Future<dynamic> createAttendance({
    required String studentId,
    required String classId,
    String? subjectId,
    required String attendanceDate,
    required String status,
    String? remarks,
  }) async {
    try {
      final response = await dioClient.dio.post(
        '/teacher/attendance',
        data: {
          'studentId': studentId,
          'classId': classId,
          if (subjectId != null) 'subjectId': subjectId,
          'attendanceDate': attendanceDate,
          'status': status,
          if (remarks != null) 'remarks': remarks,
        },
      );

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  Future<dynamic> createBulkAttendance({
    required String classId,
    String? subjectId,
    required String attendanceDate,
    required List<Map<String, dynamic>> students,
  }) async {
    final response = await dioClient.dio.post(
      '/teacher/bulk-attendance',
      data: {
        'classId': classId,

        // null = class attendance, value = subject attendance.
        // Empty strings are sent as null so Guid? binding never fails.
        'subjectId': (subjectId == null || subjectId.trim().isEmpty)
            ? null
            : subjectId,

        'attendanceDate': attendanceDate,
        'students': students,
      },
    );

    return response.data;
  }

  // ================================================================
  // GET ATTENDANCE
  // ================================================================

  Future<dynamic> getAttendance({
    String? studentId,
    String? classId,
    String? subjectId,
    String? date,
    String? session,
    String? term,
  }) async {
    try {
      final response = await dioClient.dio.get(
        '/teacher/attendance',
        queryParameters: {
          if (studentId != null) 'studentId': studentId,
          if (classId != null) 'classId': classId,
          if (subjectId != null) 'subjectId': subjectId,
          if (date != null) 'date': date,
          if (session != null) 'session': session,
          if (term != null) 'term': term,
        },
      );

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // GET SINGLE ATTENDANCE
  // ================================================================

  Future<dynamic> getAttendanceRecord({required String attendanceId}) async {
    try {
      final response = await dioClient.dio.get(
        '/teacher/attendance/$attendanceId',
      );

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // UPDATE ATTENDANCE
  // ================================================================

  Future<dynamic> updateAttendance({
    required String attendanceId,
    required String status,
    String? remarks,
  }) async {
    try {
      final response = await dioClient.dio.put(
        '/teacher/attendance/$attendanceId',
        data: {'status': status, if (remarks != null) 'remarks': remarks},
      );

      return response.data;
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }

  // ================================================================
  // DELETE ATTENDANCE
  // ================================================================

  Future<void> deleteAttendance({required String attendanceId}) async {
    try {
      await dioClient.dio.delete('/teacher/attendance/$attendanceId');
    } on DioException catch (error) {
      throw ApiErrorHandler.handle(error);
    }
  }
}