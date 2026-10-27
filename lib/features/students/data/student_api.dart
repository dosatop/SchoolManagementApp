import 'package:app/core/network/dio_client.dart';
import 'package:app/features/students/models/student_model.dart';

// ==================================================================
// STUDENT API
// ==================================================================
// Matches StudentController ([Route("api/student")]).
//
// Response shapes differ between endpoints:
//   profile / class / subjects / results -> raw data
//   attendance / assignments / submit    -> { success, data }
// _unwrap() handles both, so callers always get the data itself.

class StudentApi {
  final DioClient dioClient;

  StudentApi(this.dioClient);

  // ================================================================
  // PROFILE
  // GET /student/profile
  // ================================================================

  Future<StudentModel> getStudentProfile() async {
    final response = await dioClient.dio.get('/student/profile');

    return StudentModel.fromJson(
      Map<String, dynamic>.from(_unwrap(response.data) as Map),
    );
  }

  // ================================================================
  // CLASS
  // GET /student/class
  // ================================================================

  Future<dynamic> getStudentClass() async {
    final response = await dioClient.dio.get('/student/class');

    return _unwrap(response.data);
  }

  // ================================================================
  // SUBJECTS
  // GET /student/subjects
  // ================================================================

  Future<dynamic> getStudentSubjects() async {
    final response = await dioClient.dio.get('/student/subjects');

    return _unwrap(response.data);
  }

  // ================================================================
  // RESULTS
  // GET /student/results[?session=2026/2027&term=First Term]
  // ================================================================

  Future<dynamic> getStudentResults({
    String? session,
    String? term,
  }) async {
    final response = await dioClient.dio.get(
      '/student/results',
      queryParameters: _period(session, term),
    );

    return _unwrap(response.data);
  }

  // ================================================================
  // ATTENDANCE
  // GET /student/attendance[?session=...&term=...]
  // ================================================================

  Future<dynamic> getStudentAttendance({
    String? session,
    String? term,
  }) async {
    final response = await dioClient.dio.get(
      '/student/attendance',
      queryParameters: _period(session, term),
    );

    return _unwrap(response.data);
  }

  // ================================================================
  // ASSIGNMENTS
  // GET /student/assignments[?session=...&term=...]
  // ================================================================

  Future<dynamic> getStudentAssignments({
    String? session,
    String? term,
  }) async {
    final response = await dioClient.dio.get(
      '/student/assignments',
      queryParameters: _period(session, term),
    );

    return _unwrap(response.data);
  }

  // ================================================================
  // SINGLE ASSIGNMENT
  // GET /student/assignments/{assignmentId}
  // ================================================================

  Future<dynamic> getStudentAssignment({required String assignmentId}) async {
    final response = await dioClient.dio.get(
      '/student/assignments/$assignmentId',
    );

    return _unwrap(response.data);
  }

  // ================================================================
  // SUBMIT ASSIGNMENT
  // POST /student/assignments/{assignmentId}/submit
  // ================================================================
  // At least one of submissionText / attachmentUrl is required
  // (the backend returns 400 otherwise).

  Future<dynamic> submitAssignment({
    required String assignmentId,
    String? submissionText,
    String? attachmentUrl,
  }) async {
    final response = await dioClient.dio.post(
      '/student/assignments/$assignmentId/submit',
      data: {
        'submissionText': _nullIfBlank(submissionText),
        'attachmentUrl': _nullIfBlank(attachmentUrl),
      },
    );

    return _unwrap(response.data);
  }

  // ================================================================
  // HELPERS
  // ================================================================

  /// Returns `data` from `{ success, data }` responses, or the body
  /// itself for endpoints that return raw data.
  dynamic _unwrap(dynamic body) {
    if (body is Map && body.containsKey('success') && body.containsKey('data')) {
      return body['data'];
    }

    return body;
  }

  /// Only sends session/term when given. When left out, the backend
  /// uses the school's current session and term.
  Map<String, dynamic> _period(String? session, String? term) {
    return {
      if (_nullIfBlank(session) != null) 'session': session!.trim(),
      if (_nullIfBlank(term) != null) 'term': term!.trim(),
    };
  }

  String? _nullIfBlank(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }
}