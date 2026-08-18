import 'package:app/core/network/dio_provider.dart';
import 'package:app/features/admin/data/admin_api.dart';
import 'package:app/features/admin/data/admin_repository.dart';

import 'package:app/features/admin/models/admin_teacher_details_model.dart';
import 'package:app/features/admin/models/admin_teacher_subject_model.dart';

import 'package:app/features/admin/models/classes/admin_create_class_model.dart';

import 'package:app/features/admin/models/parents/admin_parent_child_model.dart';
import 'package:app/features/admin/models/parents/admin_parent_model.dart';

import 'package:app/features/admin/models/students/admin_class_model.dart';
import 'package:app/features/admin/models/students/admin_create_student_model.dart';
import 'package:app/features/admin/models/students/admin_edit_student_model.dart';
import 'package:app/features/admin/models/students/admin_student_detail_model.dart';
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
  return AdminRepository(
    api: ref.read(adminApiProvider),
  );
});

// ==================================================================
// ADMIN STUDENT DETAILS
// ==================================================================

final adminStudentDetailsProvider =
    FutureProvider.family<AdminStudentDetailModel, String>(
  (ref, studentId) async {
    final repository = ref.read(adminRepositoryProvider);

    return repository.getStudentDetails(
      studentId: studentId,
    );
  },
);

// ==================================================================
// ADMIN TEACHER DETAILS
// ==================================================================

final adminTeacherDetailsProvider =
    FutureProvider.family<AdminTeacherModel, String>(
  (ref, teacherId) async {
    final repository = ref.read(adminRepositoryProvider);

    return repository.getTeacherDetails(
      teacherId: teacherId,
    );
  },
);

// ==================================================================
// ADMIN PARENT DETAILS
// ==================================================================
//
// GET /api/admin/parents/:parentId
//
// The detail response contains:
// - parent information
// - schoolId
// - children
//
// children are represented by AdminParentChildModel.
// ==================================================================

final adminParentDetailsProvider =
    FutureProvider.family<AdminParentDetailModel, String>(
  (ref, parentId) async {
    final repository = ref.read(adminRepositoryProvider);

    return repository.getParentDetails(
      parentId: parentId,
    );
  },
);

// ==================================================================
// ADMIN DASHBOARD DATA
// ==================================================================

class AdminDashboardData {
  final List<AdminTeacherModel> teachers;
  final List<AdminStudentModel> students;
  final List<AdminClassModel> classes;
  final List<AdminSubjectModel> subjects;
  final List<AdminParentModel> parents;

  const AdminDashboardData({
    required this.teachers,
    required this.students,
    required this.classes,
    required this.subjects,
    required this.parents,
  });

  // ================================================================
  // COUNTS
  // ================================================================

  int get teacherCount => teachers.length;

  int get studentCount => students.length;

  int get classCount => classes.length;

  int get subjectCount => subjects.length;

  int get parentCount => parents.length;

  // ================================================================
  // COPY WITH
  // ================================================================

  AdminDashboardData copyWith({
    List<AdminTeacherModel>? teachers,
    List<AdminStudentModel>? students,
    List<AdminClassModel>? classes,
    List<AdminSubjectModel>? subjects,
    List<AdminParentModel>? parents,
  }) {
    return AdminDashboardData(
      teachers: teachers ?? this.teachers,
      students: students ?? this.students,
      classes: classes ?? this.classes,
      subjects: subjects ?? this.subjects,
      parents: parents ?? this.parents,
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

class AdminDashboardNotifier
    extends AsyncNotifier<AdminDashboardData> {

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

      // Parents belong to this admin's school.
      repository.getParents(),
    ]);

    return AdminDashboardData(
      teachers: results[0] as List<AdminTeacherModel>,
      students: results[1] as List<AdminStudentModel>,
      classes: results[2] as List<AdminClassModel>,
      subjects: results[3] as List<AdminSubjectModel>,
      parents: results[4] as List<AdminParentModel>,
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

  List<AdminTeacherModel> getTeachersForSchool(
    String schoolId,
  ) {
    final teachers = state.value?.teachers ?? [];

    return teachers
        .where((teacher) => teacher.schoolId == schoolId)
        .toList();
  }

  // ================================================================
  // GET PARENTS FOR SCHOOL
  // ================================================================
  //
  // The admin is tied to a particular school, and the backend
  // /api/admin/parents endpoint already returns the parents belonging
  // to that admin's school.
  //
  // Therefore we don't need to filter by schoolId here.
  // ================================================================

  List<AdminParentModel> getParentsForSchool(
    String schoolId,
  ) {
    return state.value?.parents ?? [];
  }

  // ================================================================
  // CREATE TEACHER
  // ================================================================

  Future<AdminTeacherModel?> createTeacher({
    required Map<String, dynamic> data,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      final teacher = await repository.createTeacher(
        data: data,
      );

      final currentState = state.value;

      if (currentState != null) {
        state = AsyncData(
          currentState.copyWith(
            teachers: [
              teacher,
              ...currentState.teachers,
            ],
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
    required String teacherId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      final updatedTeacher = await repository.updateTeacher(
        teacherId: teacherId,
        data: data,
      );

      final currentState = state.value;

      if (currentState != null) {
        final updatedTeachers =
            currentState.teachers.map((teacher) {
          if (teacher.teacherId == teacherId) {
            return updatedTeacher;
          }

          return teacher;
        }).toList();

        state = AsyncData(
          currentState.copyWith(
            teachers: updatedTeachers,
          ),
        );
      }

      ref.invalidate(
        adminTeacherDetailsProvider(teacherId),
      );

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
    required String teacherId,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      await repository.deleteTeacher(
        teacherId: teacherId,
      );

      final currentState = state.value;

      if (currentState != null) {
        state = AsyncData(
          currentState.copyWith(
            teachers: currentState.teachers
                .where(
                  (teacher) => teacher.teacherId != teacherId,
                )
                .toList(),
          ),
        );
      }

      ref.invalidate(
        adminTeacherDetailsProvider(teacherId),
      );

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
          currentState.copyWith(
            students: [
              student,
              ...currentState.students,
            ],
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
  // UPDATE STUDENT
  // ================================================================

  Future<AdminStudentModel?> updateStudent({
    required String studentId,
    required AdminEditStudentModel data,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      final updatedStudent = await repository.updateStudent(
        studentId: studentId,
        data: data,
      );

      final currentState = state.value;

      if (currentState != null) {
        final updatedStudents =
            currentState.students.map((student) {
          if (student.studentId == studentId) {
            return updatedStudent;
          }

          return student;
        }).toList();

        state = AsyncData(
          currentState.copyWith(
            students: updatedStudents,
          ),
        );
      }

      ref.invalidate(
        adminStudentDetailsProvider(studentId),
      );

      return updatedStudent;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return null;
    }
  }

  // ================================================================
  // DELETE STUDENT
  // ================================================================

  Future<bool> deleteStudent({
    required String studentId,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      await repository.deleteStudent(
        studentId: studentId,
      );

      final currentState = state.value;

      if (currentState != null) {
        final updatedStudents =
            currentState.students
                .where(
                  (student) => student.studentId != studentId,
                )
                .toList();

        state = AsyncData(
          currentState.copyWith(
            students: updatedStudents,
          ),
        );
      }

      ref.invalidate(
        adminStudentDetailsProvider(studentId),
      );

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
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
          currentState.copyWith(
            classes: [
              schoolClass,
              ...currentState.classes,
            ],
          ),
        );
      }

      return schoolClass;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return null;
    }
  }

  // ================================================================
  // CREATE SUBJECT
  // ================================================================

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
          currentState.copyWith(
            subjects: [
              subject,
              ...currentState.subjects,
            ],
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
    required String teacherId,
    required String subjectId,
    required String classId,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      await repository.assignTeacherToSubject(
        teacherId: teacherId,
        subjectId: subjectId,
        classId: classId,
      );

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
    required String assignmentId,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      await repository.unassignTeacherFromSubject(
        assignmentId: assignmentId,
      );

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  // ================================================================
  // UPDATE SUBJECT
  // ================================================================

  Future<AdminSubjectModel?> updateSubject({
    required String schoolId,
    required String subjectId,
    required AdminEditSubjectModel data,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      final updatedSubject =
          await repository.updateSubject(
        schoolId: schoolId,
        subjectId: subjectId,
        data: data,
      );

      final currentState = state.value;

      if (currentState != null) {
        final updatedSubjects =
            currentState.subjects.map((subject) {
          if (subject.subjectId == subjectId &&
              subject.schoolId == schoolId) {
            return subject.copyWith(
              subjectName: data.name,
              code: data.code,
            );
          }

          return subject;
        }).toList();

        state = AsyncData(
          currentState.copyWith(
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

      await repository.deleteSubject(
        schoolId: schoolId,
        subjectId: subjectId,
      );

      final currentState = state.value;

      if (currentState != null) {
        final updatedSubjects =
            currentState.subjects
                .where(
                  (subject) =>
                      subject.subjectId != subjectId,
                )
                .toList();

        state = AsyncData(
          currentState.copyWith(
            subjects: updatedSubjects,
          ),
        );
      }

      return true;
    } catch (error) {
      rethrow;
    }
  }

  // ================================================================
  // PARENTS
  // ================================================================

  // ------------------------------------------------
  // GET PARENT BY ID
  // ------------------------------------------------
  //
  // GET:
  // /api/admin/parents/:parentId
  //
  // Returns AdminParentDetailModel.
  // Its children are AdminParentChildModel.
  // ------------------------------------------------

  Future<AdminParentDetailModel?> getParentById({
    required String parentId,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      return await repository.getParentDetails(
        parentId: parentId,
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return null;
    }
  }

  // ------------------------------------------------
  // UPDATE PARENT
  // ------------------------------------------------
  //
  // Creation is intentionally not included yet.
  //
  // We are using Map<String, dynamic> for the update
  // body until the exact backend update DTO is defined.
  // ------------------------------------------------

  Future<AdminParentModel?> updateParent({
    required String parentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      final updatedParent =
          await repository.updateParent(
        parentId: parentId,
        data: data,
      );

      final currentState = state.value;

      if (currentState != null) {
        final updatedParents =
            currentState.parents.map((parent) {
          if (parent.parentId == parentId) {
            return updatedParent;
          }

          return parent;
        }).toList();

        state = AsyncData(
          currentState.copyWith(
            parents: updatedParents,
          ),
        );
      }

      // Refresh the detail page as well.
      ref.invalidate(
        adminParentDetailsProvider(parentId),
      );

      return updatedParent;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return null;
    }
  }

  // ------------------------------------------------
  // DELETE PARENT
  // ------------------------------------------------

  Future<bool> deleteParent({
    required String parentId,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      await repository.deleteParent(
        parentId: parentId,
      );

      final currentState = state.value;

      if (currentState != null) {
        final updatedParents =
            currentState.parents
                .where(
                  (parent) =>
                      parent.parentId != parentId,
                )
                .toList();

        state = AsyncData(
          currentState.copyWith(
            parents: updatedParents,
          ),
        );
      }

      // Invalidate parent details after deletion.
      ref.invalidate(
        adminParentDetailsProvider(parentId),
      );

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }
}