import 'package:app/features/students/data/student_api.dart';
import 'package:app/features/students/models/student_model.dart';

class StudentRepository {
  final StudentApi api;

  StudentRepository({required this.api});

  Future<StudentModel> getStudentProfile() {
    return api.getStudentProfile();
  }

  Future<dynamic> getStudentClass() {
    return api.getStudentClass();
  }

  Future<dynamic> getStudentSubjects() {
    return api.getStudentSubjects();
  }

  Future<dynamic> getStudentResults({
    String? session,
    String? term,
  }) {
    return api.getStudentResults(session: session, term: term);
  }

  Future<dynamic> getStudentAttendance({
    String? session,
    String? term,
  }) {
    return api.getStudentAttendance(session: session, term: term);
  }

  Future<dynamic> getStudentAssignments({
    String? session,
    String? term,
  }) {
    return api.getStudentAssignments(session: session, term: term);
  }

  Future<dynamic> getStudentAssignment({required String assignmentId}) {
    return api.getStudentAssignment(assignmentId: assignmentId);
  }

  Future<dynamic> submitAssignment({
    required String assignmentId,
    String? submissionText,
    String? attachmentUrl,
  }) {
    return api.submitAssignment(
      assignmentId: assignmentId,
      submissionText: submissionText,
      attachmentUrl: attachmentUrl,
    );
  }
}