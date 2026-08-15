import 'package:app/features/admin/data/admin_api.dart';
import 'package:app/features/admin/models/admin_teacher_details_model.dart';
import 'package:app/features/admin/models/classes/admin_create_class_model.dart';
import 'package:app/features/admin/models/students/admin_class_model.dart';
import 'package:app/features/admin/models/students/admin_create_student_model.dart';
import 'package:app/features/admin/models/students/admin_student_model.dart';
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
  // CREATE TEACHER
  // ================================================================

  Future<AdminTeacherModel> createTeacher({
    required String schoolId,
    required Map<String, dynamic> data,
  }) {
    return api.createTeacher(schoolId: schoolId, data: data);
  }

  // ================================================================
  // UPDATE TEACHER
  // ================================================================

  Future<AdminTeacherModel> updateTeacher({
    required String schoolId,
    required String teacherId,
    required Map<String, dynamic> data,
  }) {
    return api.updateTeacher(
      schoolId: schoolId,
      teacherId: teacherId,
      data: data,
    );
  }

  // ================================================================
  // DELETE TEACHER
  // ================================================================

  Future<void> deleteTeacher({
    required String schoolId,
    required String teacherId,
  }) {
    return api.deleteTeacher(schoolId: schoolId, teacherId: teacherId);
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

  // Future<AdminStudentModel> createStudent({
  //   required AdminCreateStudentModel data,
  // }) {
  //   return api.createStudent(data: data);
  // }

  Future<AdminStudentModel> createStudent({
    required String schoolId,
    required AdminCreateStudentModel data,
  }) {
    return api.createStudent(schoolId: schoolId, data: data);
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
    required String schoolId,
    required String teacherId,
    required String subjectId,
  }) {
    return api.assignTeacherToSubject(
      schoolId: schoolId,
      teacherId: teacherId,
      subjectId: subjectId,
    );
  }

  // ================================================================
  // UNASSIGN TEACHER FROM SUBJECT
  // ================================================================

  Future<void> unassignTeacherFromSubject({
    required String schoolId,
    required String teacherId,
    required String subjectId,
  }) {
    return api.unassignTeacherFromSubject(
      schoolId: schoolId,
      teacherId: teacherId,
      subjectId: subjectId,
    );
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
}
