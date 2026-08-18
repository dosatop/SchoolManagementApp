import 'package:app/features/admin/data/admin_api.dart';
import 'package:app/features/admin/models/admin_teacher_details_model.dart';
import 'package:app/features/admin/models/classes/admin_create_class_model.dart';
import 'package:app/features/admin/models/parents/admin_parent_child_model.dart';
import 'package:app/features/admin/models/students/admin_class_model.dart';
import 'package:app/features/admin/models/students/admin_create_student_model.dart';
import 'package:app/features/admin/models/students/admin_edit_student_model.dart';
import 'package:app/features/admin/models/students/admin_student_detail_model.dart';
import 'package:app/features/admin/models/students/admin_student_model.dart';
import 'package:app/features/admin/models/parents/admin_parent_model.dart';
import 'package:app/features/admin/models/subjects/admin_create_subject_model.dart';
import 'package:app/features/admin/models/subjects/admin_edit_subject_model.dart';
import 'package:app/features/admin/models/subjects/admin_subject_model.dart';

class AdminRepository {
  final AdminApi api;

  AdminRepository({required this.api});

  // ================================================================
  // TEACHERS
  // ================================================================

  Future<List<AdminTeacherModel>> getTeachers() {
    return api.getTeachers();
  }

  // ================================================================
  // GET TEACHER DETAILS
  // ================================================================

  Future<AdminTeacherModel> getTeacherDetails({required String teacherId}) {
    return api.getTeacherDetails(teacherId: teacherId);
  }

  // ================================================================
  // CREATE TEACHER
  // ================================================================

  Future<AdminTeacherModel> createTeacher({
    required Map<String, dynamic> data,
  }) {
    return api.createTeacher(data: data);
  }

  // ================================================================
  // UPDATE TEACHER
  // ================================================================

  Future<AdminTeacherModel> updateTeacher({
    required String teacherId,
    required Map<String, dynamic> data,
  }) {
    return api.updateTeacher(teacherId: teacherId, data: data);
  }

  // ================================================================
  // DELETE TEACHER
  // ================================================================

  Future<void> deleteTeacher({required String teacherId}) {
    return api.deleteTeacher(teacherId: teacherId);
  }

  // ================================================================
  // STUDENTS
  // ================================================================

  Future<List<AdminStudentModel>> getStudents() {
    return api.getStudents();
  }

  // ================================================================
  // CREATE STUDENT
  // ================================================================

  Future<AdminStudentModel> createStudent({
    required String schoolId,
    required AdminCreateStudentModel data,
  }) {
    return api.createStudent(schoolId: schoolId, data: data);
  }

  // ================================================================
  // STUDENT DETAILS
  // ================================================================

  Future<AdminStudentDetailModel> getStudentDetails({
    required String studentId,
  }) {
    return api.getStudentDetails(studentId: studentId);
  }

  // ================================================================
  // UPDATE STUDENT
  // ================================================================

  Future<AdminStudentModel> updateStudent({
    required String studentId,
    required AdminEditStudentModel data,
  }) {
    return api.updateStudent(studentId: studentId, data: data);
  }

  // ================================================================
  // DELETE STUDENT
  // ================================================================

  Future<void> deleteStudent({required String studentId}) {
    return api.deleteStudent(studentId: studentId);
  }

  // ================================================================
  // CLASSES
  // ================================================================

  Future<List<AdminClassModel>> getClasses() {
    return api.getClasses();
  }

  // ================================================================
  // CREATE CLASS
  // ================================================================

  Future<AdminClassModel> createClass({
    required String schoolId,
    required AdminCreateClassModel data,
  }) {
    return api.createClass(schoolId: schoolId, data: data);
  }

  // ================================================================
  // SUBJECTS
  // ================================================================

  Future<List<AdminSubjectModel>> getAdminSubjects() {
    return api.getAdminSubjects();
  }

  // ================================================================
  // CREATE SUBJECT
  // ================================================================

  Future<AdminSubjectModel> createSubject({
    required String schoolId,
    required AdminCreateSubjectModel data,
  }) {
    return api.createSubject(schoolId: schoolId, data: data);
  }

  // ================================================================
  // GET SUBJECT BY ID
  // ================================================================

  Future<AdminSubjectModel> getSubjectById({
    required String schoolId,
    required String subjectId,
  }) {
    return api.getSubjectById(schoolId: schoolId, subjectId: subjectId);
  }

  // ================================================================
  // ASSIGN TEACHER TO SUBJECT
  // ================================================================

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

  // ================================================================
  // UNASSIGN TEACHER FROM SUBJECT
  // ================================================================

  Future<void> unassignTeacherFromSubject({required String assignmentId}) {
    return api.unassignTeacherFromSubject(assignmentId: assignmentId);
  }

  // ================================================================
  // UPDATE SUBJECT
  // ================================================================

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

  // ================================================================
  // DELETE SUBJECT
  // ================================================================

  Future<void> deleteSubject({
    required String schoolId,
    required String subjectId,
  }) {
    return api.deleteSubject(schoolId: schoolId, subjectId: subjectId);
  }

  // ================================================================
  // PARENTS
  // ================================================================

  /// Get all parents belonging to the admin's school.
  Future<List<AdminParentModel>> getParents() {
    return api.getParents();
  }

  // ================================================================
  // GET PARENT DETAILS
  // ================================================================

  /// Get a single parent and their children.
  Future<AdminParentDetailModel> getParentDetails({required String parentId}) {
    return api.getParentDetails(parentId: parentId);
  }

  // ================================================================
  // UPDATE PARENT
  // ================================================================

  /// Update an existing parent.
  ///
  /// Parent creation is intentionally not included for now.
  Future<AdminParentModel> updateParent({
    required String parentId,
    required Map<String, dynamic> data,
  }) {
    return api.updateParent(parentId: parentId, data: data);
  }

  // ================================================================
  // DELETE PARENT
  // ================================================================

  Future<void> deleteParent({required String parentId}) {
    return api.deleteParent(parentId: parentId);
  }
}
