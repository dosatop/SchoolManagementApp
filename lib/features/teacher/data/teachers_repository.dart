import 'package:app/features/teacher/data/teachers_api.dart';

class TeacherRepository {
  final TeacherApi api;

  TeacherRepository({required this.api});

  // ================================================================
  // TEACHER PROFILE
  // ================================================================

  Future<dynamic> getTeacherProfile() {
    return api.getTeacherProfile();
  }

  // ================================================================
  // TEACHER CLASSES
  // ================================================================

  Future<dynamic> getTeacherClasses() {
    return api.getTeacherClasses();
  }

  // ================================================================
  // TEACHER STUDENTS
  // ================================================================

  Future<dynamic> getTeacherStudents({String? classId}) {
    return api.getTeacherStudents(classId: classId);
  }

   // ================================================================
  // GET TEACHER STUDENT DETAILS
  // ================================================================

  Future<dynamic> getStudentDetails({
    required String studentId,
  }) async {
    return api.getStudentDetails(
      studentId: studentId,
    );
  }


  // ================================================================
  // TEACHER SUBJECTS
  // ================================================================

  Future<dynamic> getTeacherSubjects() {
    return api.getTeacherSubjects();
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
  }) {
    return api.getTeacherResults(
      studentId: studentId,
      classId: classId,
      subjectId: subjectId,
      session: session,
      term: term,
    );
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
  }) {
    return api.uploadTestResult(
      studentId: studentId,
      classId: classId,
      subjectId: subjectId,
      testScore: testScore,
      remark: remark,
    );
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
  }) {
    return api.uploadExamResult(
      studentId: studentId,
      classId: classId,
      subjectId: subjectId,
      examScore: examScore,
      remark: remark,
    );
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
  }) {
    return api.uploadResult(
      studentId: studentId,
      classId: classId,
      subjectId: subjectId,
      testScore: testScore,
      examScore: examScore,
      remark: remark,
    );
  }

  // ================================================================
  // UPDATE TEST RESULT
  // ================================================================

  Future<dynamic> updateTestResult({
    required String resultId,
    required double testScore,
    String? remark,
  }) {
    return api.updateTestResult(
      resultId: resultId,
      testScore: testScore,
      remark: remark,
    );
  }

  // ================================================================
  // UPDATE EXAM RESULT
  // ================================================================

  Future<dynamic> updateExamResult({
    required String resultId,
    required double examScore,
    String? remark,
  }) {
    return api.updateExamResult(
      resultId: resultId,
      examScore: examScore,
      remark: remark,
    );
  }

  // ================================================================
  // UPDATE COMPLETE RESULT
  // ================================================================

  Future<dynamic> updateResult({
    required String resultId,
    required double testScore,
    required double examScore,
    String? remark,
  }) {
    return api.updateResult(
      resultId: resultId,
      testScore: testScore,
      examScore: examScore,
      remark: remark,
    );
  }

  // ================================================================
  // ASSIGNMENTS
  // ================================================================

  Future<dynamic> createAssignment({
    required String classId,
    required String subjectId,
    required String title,
    String? description,
    String? attachmentUrl,
    String? dueDate,
  }) {
    return api.createAssignment(
      classId: classId,
      subjectId: subjectId,
      title: title,
      description: description,
      attachmentUrl: attachmentUrl,
      dueDate: dueDate,
    );
  }

  Future<dynamic> getAssignments({
    String? classId,
    String? subjectId,
    String? session,
    String? term,
  }) {
    return api.getAssignments(
      classId: classId,
      subjectId: subjectId,
      session: session,
      term: term,
    );
  }

  Future<dynamic> getAssignment({required String assignmentId}) {
    return api.getAssignment(assignmentId: assignmentId);
  }

  Future<dynamic> updateAssignment({
    required String assignmentId,
    required String classId,
    required String subjectId,
    required String title,
    String? description,
    String? attachmentUrl,
    String? dueDate,
    required bool isPublished,
  }) {
    return api.updateAssignment(
      assignmentId: assignmentId,
      classId: classId,
      subjectId: subjectId,
      title: title,
      description: description,
      attachmentUrl: attachmentUrl,
      dueDate: dueDate,
      isPublished: isPublished,
    );
  }

  Future<dynamic> deleteAssignment({required String assignmentId}) {
    return api.deleteAssignment(assignmentId: assignmentId);
  }

  // ================================================================
  // ATTENDANCE
  // ================================================================

  Future<dynamic> createAttendance({
    required String studentId,
    required String classId,
    String? subjectId,
    required String attendanceDate,
    required String status,
    String? remarks,
  }) {
    return api.createAttendance(
      studentId: studentId,
      classId: classId,
      subjectId: subjectId,
      attendanceDate: attendanceDate,
      status: status,
      remarks: remarks,
    );
  }

  Future<dynamic> createBulkAttendance({
  required String classId,
   String? subjectId,
  required String attendanceDate,
  required List<Map<String, dynamic>> students,
}) {
  return api.createBulkAttendance(
    classId: classId,
    subjectId: subjectId,
    attendanceDate: attendanceDate,
    students: students,
  );
}


  Future<dynamic> getAttendance({
    String? studentId,
    String? classId,
    String? subjectId,
    String? date,
    String? session,
    String? term,
  }) {
    return api.getAttendance(
      studentId: studentId,
      classId: classId,
      subjectId: subjectId,
      date: date,
      session: session,
      term: term,
    );
  }

  Future<dynamic> getAttendanceRecord({required String attendanceId}) {
    return api.getAttendanceRecord(attendanceId: attendanceId);
  }

  Future<dynamic> updateAttendance({
    required String attendanceId,
    required String status,
    String? remarks,
  }) {
    return api.updateAttendance(
      attendanceId: attendanceId,
      status: status,
      remarks: remarks,
    );
  }

  Future<dynamic> deleteAttendance({required String attendanceId}) {
    return api.deleteAttendance(attendanceId: attendanceId);
  }
}
