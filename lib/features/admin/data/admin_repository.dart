import 'package:app/features/Classes/models/class_model.dart';
import 'package:app/features/admin/data/admin_api.dart';
import 'package:app/features/admin/models/academic_session/admin_academic_session_request_model.dart';

import 'package:app/features/admin/models/academic_session/current_academic_session_model.dart';
import 'package:app/features/admin/models/academic_term/academic_term_request_model.dart';
import 'package:app/features/admin/models/academic_term/admin_academic_term_model.dart';

import 'package:app/features/admin/models/admin_teacher_details_model.dart';
import 'package:app/features/admin/models/academic_session/admin_academic_session_model.dart';

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

class AdminRepository {
  final AdminApi api;

  AdminRepository({required this.api});

  // ================================================================
  // TEACHERS
  // ================================================================

  Future<List<AdminTeacherModel>> getTeachers() {
    return api.getTeachers();
  }

  Future<AdminTeacherModel> getTeacherDetails({required String teacherId}) {
    return api.getTeacherDetails(teacherId: teacherId);
  }

  Future<AdminTeacherModel> createTeacher({
    required Map<String, dynamic> data,
  }) {
    return api.createTeacher(data: data);
  }

  Future<AdminTeacherModel> updateTeacher({
    required String teacherId,
    required Map<String, dynamic> data,
  }) {
    return api.updateTeacher(teacherId: teacherId, data: data);
  }

  Future<void> deleteTeacher({required String teacherId}) {
    return api.deleteTeacher(teacherId: teacherId);
  }

  // ================================================================
  // STUDENTS
  // ================================================================

  Future<List<AdminStudentModel>> getStudents() {
    return api.getStudents();
  }

  Future<AdminStudentDetailModel> getStudentDetails({
    required String studentId,
  }) {
    return api.getStudentDetails(studentId: studentId);
  }

  Future<AdminStudentModel> createStudent({
    required String schoolId,
    required AdminCreateStudentModel data,
  }) {
    return api.createStudent(schoolId: schoolId, data: data);
  }

  Future<AdminStudentModel> updateStudent({
    required String studentId,
    required AdminEditStudentModel data,
  }) {
    return api.updateStudent(studentId: studentId, data: data);
  }

  Future<void> deleteStudent({required String studentId}) {
    return api.deleteStudent(studentId: studentId);
  }

  // ================================================================
  // CLASSES
  // ================================================================

  Future<List<AdminClassModel>> getClasses() {
    return api.getClasses();
  }

  Future<AdminClassModel> createClass({
    required String schoolId,
    required AdminCreateClassModel data,
  }) {
    return api.createClass(schoolId: schoolId, data: data);
  }

  Future<List<ClassModel>> getMySchoolClasses() {
    return api.getMySchoolClasses();
  }

  Future<AdminClassSubjectModel> assignSubjectToClass({
    required AdminAssignClassSubjectRequest data,
  }) {
    return api.assignSubjectToClass(data: data);
  }

  Future<List<AdminGetClassSubjectModel>> getAdminClassSubjects(
    String classId,
  ) {
    return api.getAdminClassSubjects(classId: classId);
  }

  Future<void> unassignSubjectFromClass({
    required String classId,
    required String subjectId,
  }) {
    return api.unassignSubjectFromClass(classId: classId, subjectId: subjectId);
  }

  Future<AdminClassModel> assignClassTeacher({
    required String classId,
    required String teacherId,
  }) {
    return api.assignClassTeacher(classId: classId, teacherId: teacherId);
  }

  // ================================================================
  // SUBJECTS
  // ================================================================

  Future<List<AdminSubjectModel>> getAdminSubjects() {
    return api.getAdminSubjects();
  }

  Future<AdminSubjectModel> createSubject({
    required String schoolId,
    required AdminCreateSubjectModel data,
  }) {
    return api.createSubject(schoolId: schoolId, data: data);
  }

  Future<AdminSubjectModel> getSubjectById({
    required String schoolId,
    required String subjectId,
  }) {
    return api.getSubjectById(schoolId: schoolId, subjectId: subjectId);
  }

  Future<AdminSubjectModel> updateSubject({
    required String schoolId,
    required String subjectId,
    required AdminEditSubjectModel data,
  }) {
    return api.updateSubject(
      schoolId: schoolId,
      subjectId: subjectId,
      data: data,
    );
  }

  Future<void> deleteSubject({
    required String schoolId,
    required String subjectId,
  }) {
    return api.deleteSubject(schoolId: schoolId, subjectId: subjectId);
  }

  Future<void> assignTeacherToSubject({
    required String teacherId,
    required String subjectId,
    required String classId,
  }) {
    return api.assignTeacherToSubject(
      teacherId: teacherId,
      subjectId: subjectId,
      classId: classId,
    );
  }

  Future<List<AdminSubjectTeacherModel>> getTeachersForSubject({
    required String subjectId,
  }) {
    return api.getTeachersForSubject(subjectId: subjectId);
  }

  Future<void> unassignTeacherFromSubject({required String assignmentId}) {
    return api.unassignTeacherFromSubject(assignmentId: assignmentId);
  }

  // ================================================================
  // PARENTS
  // ================================================================

  Future<List<AdminParentModel>> getParents() {
    return api.getParents();
  }

  Future<AdminParentDetailModel> getParentDetails({required String parentId}) {
    return api.getParentDetails(parentId: parentId);
  }

  Future<AdminParentModel> updateParent({
    required String parentId,
    required Map<String, dynamic> data,
  }) {
    return api.updateParent(parentId: parentId, data: data);
  }

  Future<void> deleteParent({required String parentId}) {
    return api.deleteParent(parentId: parentId);
  }

  // ================================================================
  // DEPARTMENTS
  // ================================================================

  Future<List<AdminDepartmentModel>> getDepartments() {
    return api.getDepartments();
  }

  // ================================================================
  // TRADES
  // ================================================================

  Future<List<AdminTradeModel>> getTrades() {
    return api.getTrades();
  }

  // ================================================================
  // ATTENDANCE
  // ================================================================

  Future<AdminStudentAttendanceModel> getStudentAttendance({
    required String studentId,
    required String session,
    required String term,
  }) {
    return api.getStudentAttendance(
      studentId: studentId,
      session: session,
      term: term,
    );
  }

  // ================================================================
  // RESULTS
  // ================================================================

  Future<AdminResultsResponse> getResultsForSchool({
    required String schoolId,
    String? session,
    String? term,
  }) {
    return api.getResultsForSchool(
      schoolId: schoolId,
      session: session,
      term: term,
    );
  }

  Future<AdminResultModel> createResult(CreateAdminResultRequest request) {
    return api.createResult(request);
  }

  Future<AdminResultModel> createTestResult(CreateAdminResultRequest request) {
    return api.createTestResult(request);
  }

  Future<AdminResultModel> createExamResult(CreateAdminResultRequest request) {
    return api.createExamResult(request);
  }

  Future<AdminResultModel> getResult({required String resultId}) {
    return api.getResult(resultId: resultId);
  }

  Future<AdminResultsResponse> getStudentResults({
    required String studentId,
    required String session,
    required String term,
  }) {
    return api.getStudentResults(
      studentId: studentId,
      session: session,
      term: term,
    );
  }

  Future<AdminResultsResponse> getClassResults({
    required String classId,
    required String session,
    required String term,
  }) {
    return api.getClassResults(classId: classId, session: session, term: term);
  }

  Future<AdminResultsResponse> getSubjectResults({
    required String subjectId,
    required String classId,
    required String session,
    required String term,
  }) {
    return api.getSubjectResults(
      subjectId: subjectId,
      classId: classId,
      session: session,
      term: term,
    );
  }

  Future<AdminResultModel> updateResult({
    required String resultId,
    required UpdateAdminResultRequest request,
  }) {
    return api.updateResult(resultId: resultId, request: request);
  }

  Future<void> deleteResult({required String resultId}) {
    return api.deleteResult(resultId: resultId);
  }

  // ================================================================
  // ACADEMIC SESSION
  // ================================================================

  Future<AdminAcademicSessionModel> createAcademicSession({
    required AdminAcademicSessionRequestModel data,
  }) {
    return api.createAcademicSession(data: data);
  }

  Future<List<AdminAcademicSessionModel>> getAcademicSessions() {
    return api.getAcademicSessions();
  }

  Future<CurrentAcademicSessionModel> getCurrentAcademicSession({
    required String schoolId,
  }) {
    return api.getCurrentAcademicSession(schoolId: schoolId);
  }

  Future<AdminAcademicSessionModel> setActiveAcademicSession({
    required String sessionId,
  }) {
    return api.setActiveAcademicSession(sessionId: sessionId);
  }

  Future<AdminAcademicSessionModel> updateAcademicSession({
    required String sessionId,
    required AdminAcademicSessionRequestModel data,
  }) {
    return api.updateAcademicSession(sessionId: sessionId, data: data);
  }

  Future<void> deleteAcademicSession({required String sessionId}) {
    return api.deleteAcademicSession(sessionId: sessionId);
  }

  // ================================================================
  // CREATE TERM
  // ================================================================

  Future<AdminAcademicTermModel> createAcademicTerm({
    required AdminAcademicTermRequestModel data,
  }) async {
    return await api.createAcademicTerm(data: data);
  }

  // ================================================================
  // GET ALL TERMS FOR A SESSION
  // ================================================================

  Future<List<AdminAcademicTermModel>> getAcademicTerms({
    required String academicSessionId,
  }) async {
    return await api.getAcademicTerms(academicSessionId: academicSessionId);
  }

  // ================================================================
  // GET PARTICULAR TERM
  // ================================================================

  Future<AdminAcademicTermModel> getAcademicTerm({
    required String termId,
  }) async {
    return await api.getAcademicTerm(termId: termId);
  }

  // ================================================================
  // UPDATE TERM
  // ================================================================

  Future<AdminAcademicTermModel> updateAcademicTerm({
    required String termId,
    required AdminAcademicTermRequestModel data,
  }) async {
    return await api.updateAcademicTerm(termId: termId, data: data);
  }

  // ================================================================
  // DELETE TERM
  // ================================================================

  Future<void> deleteAcademicTerm({required String termId}) async {
    await api.deleteAcademicTerm(termId: termId);
  }

  Future<Map<String, dynamic>> assignStudentToTrade({
    required String studentId,
    required String tradeId,
    required String tradeSubjectId,
  }) {
    return api.assignStudentToTrade(
      studentId: studentId,
      tradeId: tradeId,
      tradeSubjectId: tradeSubjectId,
    );
  }

  // Future<Map<String, dynamic>> assignStudentToTradeWithoutSubject({
  //   required String studentId,
  //   required String tradeId,
  // }) {
  //   return api.assignStudentToTradeWithoutSubject(
  //     studentId: studentId,
  //     tradeId: tradeId,
  //   );
  // }

  Future<Map<String, dynamic>> unassignStudentFromTrade({
    required String studentId,
  }) {
    return api.unassignStudentFromTrade(studentId: studentId);
  }
}
