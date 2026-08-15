import 'package:app/core/network/dio_provider.dart';
import 'package:app/features/admin/data/admin_api.dart';
import 'package:app/features/admin/data/admin_repository.dart';
import 'package:app/features/admin/models/admin_teacher_details_model.dart';
import 'package:app/features/admin/models/classes/admin_create_class_model.dart';
import 'package:app/features/admin/models/students/admin_class_model.dart';
import 'package:app/features/admin/models/students/admin_create_student_model.dart';
import 'package:app/features/admin/models/students/admin_student_model.dart';
import 'package:app/features/admin/models/subjects/admin_create_subject_model.dart';
import 'package:app/features/admin/models/subjects/admin_edit_subject_model.dart';
import 'package:app/features/admin/models/subjects/admin_subject_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==================================================================
// ADMIN API
// ==================================================================

final adminApiProvider = Provider<AdminApi>((ref) {
  return AdminApi(ref.read(dioClientProvider));
});

// ==================================================================
// ADMIN REPOSITORY
// ==================================================================

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(api: ref.read(adminApiProvider));
});

// ==================================================================
// ADMIN DASHBOARD DATA
// ==================================================================

class AdminDashboardData {
  final List<AdminTeacherModel> teachers;
  final List<AdminStudentModel> students;
  final List<AdminClassModel> classes;
  final List<AdminSubjectModel> subjects;

  const AdminDashboardData({
    required this.teachers,
    required this.students,
    required this.classes,
    required this.subjects,
  });

  int get teacherCount => teachers.length;

  int get studentCount => students.length;

  int get classCount => classes.length;

  int get subjectCount => subjects.length;

  AdminDashboardData copyWith({
    List<AdminTeacherModel>? teachers,
    List<AdminStudentModel>? students,
    List<AdminClassModel>? classes,
    List<AdminSubjectModel>? subjects,
  }) {
    return AdminDashboardData(
      teachers: teachers ?? this.teachers,
      students: students ?? this.students,
      classes: classes ?? this.classes,
      subjects: subjects ?? this.subjects,
    );
  }
}

// ==================================================================
// ADMIN PROVIDER
// ==================================================================

final adminDashboardProvider =
    AsyncNotifierProvider<AdminDashboardNotifier, AdminDashboardData>(
      AdminDashboardNotifier.new,
    );

class AdminDashboardNotifier extends AsyncNotifier<AdminDashboardData> {
  // ================================================================
  // BUILD
  // ================================================================

  @override
  Future<AdminDashboardData> build() async {
    return _loadDashboard();
  }

  // ================================================================
  // LOAD DASHBOARD
  // ================================================================

  Future<AdminDashboardData> _loadDashboard() async {
    final repository = ref.read(adminRepositoryProvider);

    final results = await Future.wait([
      repository.getTeachers(),
      repository.getStudents(),
      repository.getClasses(),
      repository.getAdminSubjects(),
    ]);

    return AdminDashboardData(
      teachers: results[0] as List<AdminTeacherModel>,
      students: results[1] as List<AdminStudentModel>,
      classes: results[2] as List<AdminClassModel>,
      subjects: results[3] as List<AdminSubjectModel>,
    );
  }

  // ================================================================
  // REFRESH
  // ================================================================

  Future<void> refresh() async {
    state = const AsyncLoading();

    try {
      final dashboard = await _loadDashboard();

      state = AsyncData(dashboard);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  // ================================================================
  // GET TEACHERS FOR SCHOOL
  // ================================================================

  List<AdminTeacherModel> getTeachersForSchool(String schoolId) {
    final teachers = state.value?.teachers ?? [];

    return teachers.where((teacher) => teacher.schoolId == schoolId).toList();
  }

  // ================================================================
  // CREATE TEACHER
  // ================================================================

  Future<AdminTeacherModel?> createTeacher({
    required String schoolId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      final teacher = await repository.createTeacher(
        schoolId: schoolId,
        data: data,
      );

      final currentState = state.value;

      if (currentState != null) {
        state = AsyncData(
          AdminDashboardData(
            teachers: [teacher, ...currentState.teachers],
            students: currentState.students,
            classes: currentState.classes,
            subjects: currentState.subjects,
          ),
        );
      }

      return teacher;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return null;
    }
  }

  // ================================================================
  // UPDATE TEACHER
  // ================================================================

  Future<AdminTeacherModel?> updateTeacher({
    required String schoolId,
    required String teacherId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      final updatedTeacher = await repository.updateTeacher(
        schoolId: schoolId,
        teacherId: teacherId,
        data: data,
      );

      final currentState = state.value;

      if (currentState != null) {
        final updatedTeachers = currentState.teachers.map((teacher) {
          if (teacher.teacherId == teacherId) {
            return updatedTeacher;
          }

          return teacher;
        }).toList();

        state = AsyncData(
          AdminDashboardData(
            teachers: updatedTeachers,
            students: currentState.students,
            classes: currentState.classes,
            subjects: currentState.subjects,
          ),
        );
      }

      return updatedTeacher;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return null;
    }
  }

  // ================================================================
  // DELETE TEACHER
  // ================================================================

  Future<bool> deleteTeacher({
    required String schoolId,
    required String teacherId,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      await repository.deleteTeacher(schoolId: schoolId, teacherId: teacherId);

      final currentState = state.value;

      if (currentState != null) {
        final updatedTeachers = currentState.teachers
            .where((teacher) => teacher.teacherId != teacherId)
            .toList();

        state = AsyncData(
          AdminDashboardData(
            teachers: updatedTeachers,
            students: currentState.students,
            classes: currentState.classes,
            subjects: currentState.subjects,
          ),
        );
      }

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  // ================================================================
  // CREATE STUDENT
  // ================================================================

  Future<AdminStudentModel?> createStudent({
    required String schoolId,
    required AdminCreateStudentModel data,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      final student = await repository.createStudent(
        schoolId: schoolId,
        data: data,
      );

      final currentState = state.value;

      if (currentState != null) {
        state = AsyncData(
          AdminDashboardData(
            teachers: currentState.teachers,
            students: [student, ...currentState.students],
            classes: currentState.classes,
            subjects: currentState.subjects,
          ),
        );
      }

      return student;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  // ================================================================
  // CREATE CLASS
  // ================================================================

  Future<AdminClassModel?> createClass({
    required String schoolId,
    required AdminCreateClassModel data,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      final schoolClass = await repository.createClass(
        schoolId: schoolId,
        data: data,
      );

      final currentState = state.value;

      if (currentState != null) {
        state = AsyncData(
          AdminDashboardData(
            teachers: currentState.teachers,
            students: currentState.students,
            classes: [schoolClass, ...currentState.classes],
            subjects: currentState.subjects,
          ),
        );
      }

      return schoolClass;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return null;
    }
  }

  Future<AdminSubjectModel?> createSubject({
    required String schoolId,
    required AdminCreateSubjectModel data,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      final subject = await repository.createSubject(
        schoolId: schoolId,
        data: data,
      );

      final currentState = state.value;

      if (currentState != null) {
        state = AsyncData(
          AdminDashboardData(
            teachers: currentState.teachers,
            students: currentState.students,
            classes: currentState.classes,
            subjects: [subject, ...currentState.subjects],
          ),
        );
      }

      return subject;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return null;
    }
  }

  // ================================================================
  // GET SUBJECT BY ID
  // ================================================================

  Future<AdminSubjectModel?> getSubjectById({
    required String schoolId,
    required String subjectId,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      return await repository.getSubjectById(
        schoolId: schoolId,
        subjectId: subjectId,
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return null;
    }
  }

  // ================================================================
  // ASSIGN TEACHER TO SUBJECT
  // ================================================================

  Future<bool> assignTeacherToSubject({
    required String schoolId,
    required String teacherId,
    required String subjectId,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      await repository.assignTeacherToSubject(
        schoolId: schoolId,
        teacherId: teacherId,
        subjectId: subjectId,
      );

      final currentState = state.value;

      if (currentState != null) {
        final teacher = currentState.teachers.firstWhere(
          (item) => item.teacherId == teacherId,
        );

        final updatedSubjects = currentState.subjects.map((subject) {
          if (subject.subjectId != subjectId) {
            return subject;
          }

          // Don't add the same teacher twice.
          final alreadyAssigned = subject.teacherSubjects.any(
            (assigned) => assigned.teacherId == teacherId,
          );

          if (alreadyAssigned) {
            return subject;
          }

          final assignedTeacher = AdminSubjectTeacherModel(
            teacherId: teacher.teacherId,
            teacherName: teacher.teacherName,
            email: teacher.email,
            phoneNumber: teacher.phoneNumber,
          );

          return subject.copyWith(
            teacherSubjects: [...subject.teacherSubjects, assignedTeacher],
          );
        }).toList();

        state = AsyncData(currentState.copyWith(subjects: updatedSubjects));
      }

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  // ================================================================
  // UNASSIGN TEACHER FROM SUBJECT
  // ================================================================

  Future<bool> unassignTeacherFromSubject({
    required String schoolId,
    required String teacherId,
    required String subjectId,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      await repository.unassignTeacherFromSubject(
        schoolId: schoolId,
        teacherId: teacherId,
        subjectId: subjectId,
      );

      final currentState = state.value;

      if (currentState != null) {
        final updatedSubjects = currentState.subjects.map((subject) {
          if (subject.subjectId != subjectId) {
            return subject;
          }

          final updatedTeachers = subject.teacherSubjects
              .where((teacher) => teacher.teacherId != teacherId)
              .toList();

          return subject.copyWith(teacherSubjects: updatedTeachers);
        }).toList();

        state = AsyncData(currentState.copyWith(subjects: updatedSubjects));
      }

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }

  Future<AdminSubjectModel?> updateSubject({
    required String schoolId,
    required String subjectId,
    required AdminEditSubjectModel data,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      // Send update to backend.
      final updatedSubject = await repository.updateSubject(
        schoolId: schoolId,
        subjectId: subjectId,
        data: data,
      );

      final currentState = state.value;

      if (currentState != null) {
        final updatedSubjects = currentState.subjects.map((subject) {
          if (subject.subjectId == subjectId && subject.schoolId == schoolId) {
            // Keep the existing IDs and assigned teachers.
            // Only update the editable fields.
            return subject.copyWith(subjectName: data.name, code: data.code);
          }

          return subject;
        }).toList();

        state = AsyncData(
          AdminDashboardData(
            teachers: currentState.teachers,
            students: currentState.students,
            classes: currentState.classes,
            subjects: updatedSubjects,
          ),
        );
      }

      return updatedSubject;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return null;
    }
  }

  // ================================================================
  // DELETE SUBJECT
  // ================================================================

  Future<bool> deleteSubject({
    required String schoolId,
    required String subjectId,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      await repository.deleteSubject(schoolId: schoolId, subjectId: subjectId);

      final currentState = state.value;

      if (currentState != null) {
        final updatedSubjects = currentState.subjects
            .where((subject) => subject.subjectId != subjectId)
            .toList();

        state = AsyncData(
          AdminDashboardData(
            teachers: currentState.teachers,
            students: currentState.students,
            classes: currentState.classes,
            subjects: updatedSubjects,
          ),
        );
      }

      return true;
    } catch (error) {
      // Don't change the dashboard state to AsyncError here.
      // The current page can continue displaying normally.
      rethrow;
    }
  }
}
