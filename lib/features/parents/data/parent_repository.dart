import 'package:app/features/parents/data/parents_api.dart';
import 'package:app/features/parents/models/parent_child_model.dart';
import 'package:app/features/parents/models/parent_model.dart';
import 'package:app/features/parents/models/parent_result_model.dart';

// ==================================================================
// PARENT REPOSITORY
// ==================================================================
// Session/term are optional on child data — leave them null for the
// school's current session and term.

class ParentRepository {
  ParentRepository(this.api);

  final ParentApi api;

  // ---------------- PROFILE + CHILDREN ----------------

  Future<ParentModel> getProfile() => api.getProfile();

  Future<dynamic> getProfileData() => api.getProfileData();

  Future<List<ParentChildModel>> getChildren() => api.getChildren();

  Future<ParentChildModel> getChild(String studentId) =>
      api.getChild(studentId);

  // ---------------- CHILD DATA ----------------

  Future<dynamic> getChildClass(String studentId) =>
      api.getChildClass(studentId);

  Future<dynamic> getChildSubjects(String studentId) =>
      api.getChildSubjects(studentId);

  Future<dynamic> getChildResultsData(
    String studentId, {
    String? session,
    String? term,
  }) => api.getChildResultsData(studentId, session: session, term: term);

  Future<dynamic> getChildAttendance(
    String studentId, {
    String? session,
    String? term,
  }) => api.getChildAttendance(studentId, session: session, term: term);

  Future<dynamic> getChildAssignments(
    String studentId, {
    String? session,
    String? term,
  }) => api.getChildAssignments(studentId, session: session, term: term);

  Future<dynamic> getChildAssignment(String studentId, String assignmentId) =>
      api.getChildAssignment(studentId, assignmentId);

  // ---------------- LEGACY ----------------

  Future<List<ParentResultModel>> getChildResults(
    String studentId,
    String session,
    String term,
  ) => api.getChildResults(studentId, session, term);
}