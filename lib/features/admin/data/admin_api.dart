import 'package:app/core/network/dio_client.dart';
import 'package:app/features/Classes/models/class_model.dart';
import 'package:app/features/admin/models/academic_session/current_academic_session_model.dart';
import 'package:app/features/admin/models/admin_teacher_details_model.dart';
import 'package:app/features/admin/models/attendance/admin_attendance_model.dart';
import 'package:app/features/admin/models/classes/admin_create_class_model.dart';
import 'package:app/features/admin/models/parents/admin_parent_child_model.dart';
import 'package:app/features/admin/models/parents/admin_parent_model.dart';
import 'package:app/features/admin/models/results/admin_result_model.dart';
import 'package:app/features/admin/models/students/admin_class_model.dart';
import 'package:app/features/admin/models/students/admin_create_student_model.dart';
import 'package:app/features/admin/models/students/admin_edit_student_model.dart';
import 'package:app/features/admin/models/students/admin_student_detail_model.dart';
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
  // GET TEACHER DETAILS
  // ================================================================

  Future<AdminTeacherModel> getTeacherDetails({
    required String teacherId,
  }) async {
    final response = await dioClient.dio.get('/admin/teachers/$teacherId');

    return AdminTeacherModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  // ================================================================
  // CREATE TEACHER
  // ================================================================

  Future<AdminTeacherModel> createTeacher({
    required Map<String, dynamic> data,
  }) async {
    final response = await dioClient.dio.post('/admin/teachers', data: data);

    return AdminTeacherModel.fromJson(Map<String, dynamic>.from(response.data));
  }
  // ================================================================
  // UPDATE TEACHER
  // ================================================================

  Future<AdminTeacherModel> updateTeacher({
    required String teacherId,
    required Map<String, dynamic> data,
  }) async {
    final response = await dioClient.dio.put(
      '/admin/teachers/$teacherId',
      data: data,
    );

    return AdminTeacherModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  // ================================================================
  // DELETE TEACHER
  // ================================================================

  Future<void> deleteTeacher({required String teacherId}) async {
    await dioClient.dio.delete('/admin/teachers/$teacherId');
  }
  // ================================================================
  // STUDENTS
  // ================================================================

  // Future<List<AdminStudentModel>> getStudents() async {
  //   final response = await dioClient.dio.get('/admin/students');

  //   final data = response.data as List;

  //   return data
  //       .map(
  //         (json) => AdminStudentModel.fromJson(Map<String, dynamic>.from(json)),
  //       )
  //       .toList();
  // }

  Future<List<AdminStudentModel>> getStudents() async {
    final response = await dioClient.dio.get('/admin/students');

    final data = Map<String, dynamic>.from(response.data);

    final students = data['students'] as List<dynamic>? ?? [];

    return students
        .map(
          (json) => AdminStudentModel.fromJson(
            Map<String, dynamic>.from(json as Map),
          ),
        )
        .toList();
  }

  // ================================================================
  // STUDENT DETAILS
  // ================================================================

  Future<AdminStudentDetailModel> getStudentDetails({
    required String studentId,
  }) async {
    final response = await dioClient.dio.get(
      '/admin/students/$studentId/records',
    );

    return AdminStudentDetailModel.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  // ================================================================
  // UPDATE STUDENT
  // ================================================================

  Future<AdminStudentModel> updateStudent({
    required String studentId,
    required AdminEditStudentModel data,
  }) async {
    final response = await dioClient.dio.put(
      '/admin/students/$studentId',
      data: data.toJson(),
    );

    return AdminStudentModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  // ================================================================
  // DELETE STUDENT
  // ================================================================

  Future<void> deleteStudent({required String studentId}) async {
    await dioClient.dio.delete('/admin/students/$studentId');
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
    required String teacherId,
    required String subjectId,
    required String classId,
  }) async {
    await dioClient.dio.post(
      '/admin/teachers/$teacherId/teaching-assignments',
      data: {'subjectId': subjectId, 'classId': classId},
    );
  }

  // ================================================================
  // UNASSIGN TEACHER FROM SUBJECT
  // ================================================================

  Future<void> unassignTeacherFromSubject({
    required String assignmentId,
  }) async {
    await dioClient.dio.delete('/admin/teaching-subjects/$assignmentId');
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

  // ================================================================
  // PARENTS
  // ================================================================

  /// Get all parents belonging to the admin's school.
  Future<List<AdminParentModel>> getParents() async {
    final response = await dioClient.dio.get('/admin/parents');

    final data = response.data as List;

    return data
        .map((json) => AdminParentModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a single parent with their children.
  Future<AdminParentDetailModel> getParentDetails({
    required String parentId,
  }) async {
    final response = await dioClient.dio.get('/admin/parents/$parentId');

    return AdminParentDetailModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Update an existing parent.
  ///
  /// Creation is intentionally not included for now.
  Future<AdminParentModel> updateParent({
    required String parentId,
    required Map<String, dynamic> data,
  }) async {
    final response = await dioClient.dio.put(
      '/admin/parents/$parentId',
      data: data,
    );

    return AdminParentModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Delete a parent.
  Future<void> deleteParent({required String parentId}) async {
    await dioClient.dio.delete('/admin/parents/$parentId');
  }

  // ================================================================
  // STUDENT ATTENDANCE
  // ================================================================

  Future<AdminStudentAttendanceModel> getStudentAttendance({
    required String studentId,
    required String session,
    required String term,
  }) async {
    final response = await dioClient.dio.get(
      '/admin/students/$studentId/attendance',
      queryParameters: {'session': session, 'term': term},
    );

    return AdminStudentAttendanceModel.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }


  // ================================================================
// GET RESULTS FOR SCHOOL
// ================================================================
//
// GET /api/admin/results
//
// Optional:
// - session
// - term
//
// Returns all results belonging to the school.
// ================================================================

Future<AdminResultsResponse> getResultsForSchool({
  required String schoolId,
  String? session,
  String? term,
}) async {
  final response = await dioClient.dio.get(
    '/admin/results',
    queryParameters: {
      'schoolId': schoolId,
      if (session != null && session.isNotEmpty)
        'session': session,
      if (term != null && term.isNotEmpty)
        'term': term,
    },
  );

  return AdminResultsResponse.fromJson(
    response.data,
  );
}


  // ================================================================
  // CREATE RESULT
  // ================================================================

  Future<AdminResultModel> createResult(
    CreateAdminResultRequest request,
  ) async {
    final response = await dioClient.dio.post(
      '/admin/results',
      data: request.toJson(),
    );

    return AdminResultModel.fromJson(Map<String, dynamic>.from(response.data));
  }
// ================================================================
// CREATE TEST RESULT
// ================================================================

Future<AdminResultModel> createTestResult(
  CreateAdminResultRequest request,
) async {
  final response = await dioClient.dio.post(
    '/admin/results/test',
    data: request.toJson(),
  );

  return AdminResultModel.fromJson(
    Map<String, dynamic>.from(response.data),
  );
}

// ================================================================
// CREATE EXAM RESULT
// ================================================================

Future<AdminResultModel> createExamResult(
  CreateAdminResultRequest request,
) async {
  final response = await dioClient.dio.post(
    '/admin/results/exam',
    data: request.toJson(),
  );

  return AdminResultModel.fromJson(
    Map<String, dynamic>.from(response.data),
  );
}


  // ================================================================
  // GET RESULT
  // ================================================================

  Future<AdminResultModel> getResult({required String resultId}) async {
    final response = await dioClient.dio.get('/admin/results/$resultId');

    return AdminResultModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  // ================================================================
  // GET STUDENT RESULTS
  // ================================================================

  Future<AdminResultsResponse> getStudentResults({
    required String studentId,
    required String session,
    required String term,
  }) async {
    final response = await dioClient.dio.get(
      '/admin/students/$studentId/results',
      queryParameters: {'session': session, 'term': term},
    );

    return AdminResultsResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }

  // ================================================================
  // GET CLASS RESULTS
  // ================================================================

  Future<AdminResultsResponse> getClassResults({
    required String classId,
    required String session,
    required String term,
  }) async {
    final response = await dioClient.dio.get(
      '/admin/classes/$classId/results',
      queryParameters: {'session': session, 'term': term},
    );

    return AdminResultsResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
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
    final response = await dioClient.dio.get(
      '/admin/subjects/$subjectId/results',
      queryParameters: {'classId': classId, 'session': session, 'term': term},
    );

    return AdminResultsResponse.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }
  // ================================================================
  // UPDATE RESULT
  // ================================================================

  Future<AdminResultModel> updateResult({
    required String resultId,
    required UpdateAdminResultRequest request,
  }) async {
    final response = await dioClient.dio.put(
      '/admin/results/$resultId',
      data: request.toJson(),
    );

    return AdminResultModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  // ================================================================
  // DELETE RESULT
  // ================================================================

  Future<void> deleteResult({required String resultId}) async {
    await dioClient.dio.delete('/admin/results/$resultId');
  }

 Future<CurrentAcademicSessionModel> getCurrentAcademicSession({
  required String schoolId,
}) async {
  final response = await dioClient.dio.get(
    '/academic-sessions/current',
    queryParameters: {
      'schoolId': schoolId,
    },
  );

  return CurrentAcademicSessionModel.fromJson(
    Map<String, dynamic>.from(response.data),
  );
}


}
