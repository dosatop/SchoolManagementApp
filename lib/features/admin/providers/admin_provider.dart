import 'package:app/core/network/dio_provider.dart';
import 'package:app/features/admin/data/admin_api.dart';
import 'package:app/features/admin/data/admin_repository.dart';

import 'package:app/features/admin/models/academic_session/current_academic_session_model.dart';

import 'package:app/features/admin/models/admin_teacher_details_model.dart';
import 'package:app/features/admin/models/attendance/admin_attendance_model.dart';

import 'package:app/features/admin/models/classes/admin_create_class_model.dart';

import 'package:app/features/admin/models/parents/admin_parent_child_model.dart';
import 'package:app/features/admin/models/parents/admin_parent_model.dart';

import 'package:app/features/admin/models/results/admin_result_model.dart';

import 'package:app/features/admin/models/classes/admin_class_model.dart';
import 'package:app/features/admin/models/students/admin_create_student_model.dart';
import 'package:app/features/admin/models/students/admin_department_model.dart';
import 'package:app/features/admin/models/students/admin_edit_student_model.dart';
import 'package:app/features/admin/models/students/admin_student_detail_model.dart';
import 'package:app/features/admin/models/students/admin_student_model.dart';

import 'package:app/features/admin/models/subjects/admin_create_subject_model.dart';
import 'package:app/features/admin/models/subjects/admin_edit_subject_model.dart';
import 'package:app/features/admin/models/subjects/admin_subject_model.dart';
import 'package:app/features/admin/models/subjects/admin_trade_model.dart';

// ================================================================
// DEPARTMENT MODEL
// ================================================================
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==================================================================
// ADMIN REPOSITORY
// ==================================================================

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  final adminApi = AdminApi(dioClient);

  return AdminRepository(api: adminApi);
});

// ==================================================================
// ADMIN STUDENT DETAILS
// ==================================================================

final adminStudentDetailsProvider =
    FutureProvider.family<AdminStudentDetailModel, String>((
      ref,
      studentId,
    ) async {
      final repository = ref.read(adminRepositoryProvider);

      return repository.getStudentDetails(studentId: studentId);
    });

// ==================================================================
// TEACHERS ASSIGNED TO SUBJECT
// ==================================================================
//
// GET /api/admin/{subjectId}/teachers
// ==================================================================

final adminSubjectTeachersProvider = FutureProvider.autoDispose
    .family<List<AdminSubjectTeacherModel>, String>((ref, subjectId) async {
      final repository = ref.read(adminRepositoryProvider);

      return repository.getTeachersForSubject(subjectId: subjectId);
    });

// ==================================================================
// ADMIN TEACHER DETAILS
// ==================================================================

final adminTeacherDetailsProvider =
    FutureProvider.family<AdminTeacherModel, String>((ref, teacherId) async {
      final repository = ref.read(adminRepositoryProvider);

      return repository.getTeacherDetails(teacherId: teacherId);
    });

// ==================================================================
// ADMIN PARENT DETAILS
// ==================================================================

final adminParentDetailsProvider =
    FutureProvider.family<AdminParentDetailModel, String>((
      ref,
      parentId,
    ) async {
      final repository = ref.read(adminRepositoryProvider);

      return repository.getParentDetails(parentId: parentId);
    });

// ==================================================================
// ADMIN RESULT DETAILS
// ==================================================================
//
// GET /api/admin/results/:resultId
// ==================================================================

final adminResultDetailsProvider =
    FutureProvider.family<AdminResultModel, String>((ref, resultId) async {
      final repository = ref.read(adminRepositoryProvider);

      return repository.getResult(resultId: resultId);
    });

// ==================================================================
// CURRENT ACADEMIC SESSION
// ==================================================================

final currentAcademicSessionProvider =
    FutureProvider.family<CurrentAcademicSessionModel, String>((
      ref,
      schoolId,
    ) async {
      final repository = ref.read(adminRepositoryProvider);

      return repository.getCurrentAcademicSession(schoolId: schoolId);
    });

// ==================================================================
// ADMIN CLASS ATTENDANCE PARAMS
// ==================================================================

class AdminClassAttendanceParams {
  final List<String> studentIds;
  final String session;
  final String term;

  const AdminClassAttendanceParams({
    required this.studentIds,
    required this.session,
    required this.term,
  });

  @override
  bool operator ==(Object other) {
    return other is AdminClassAttendanceParams &&
        _listEquals(other.studentIds, studentIds) &&
        other.session == session &&
        other.term == term;
  }

  @override
  int get hashCode {
    return Object.hash(Object.hashAll(studentIds), session, term);
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }

    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }

    return true;
  }
}

// ==================================================================
// ADMIN CLASS ATTENDANCE
// ==================================================================

final adminClassAttendanceProvider = FutureProvider.autoDispose
    .family<List<AdminStudentAttendanceModel>, AdminClassAttendanceParams>((
      ref,
      params,
    ) async {
      final repository = ref.read(adminRepositoryProvider);

      if (params.studentIds.isEmpty) {
        return [];
      }

      final results = <AdminStudentAttendanceModel>[];

      for (final studentId in params.studentIds) {
        try {
          final attendance = await repository.getStudentAttendance(
            studentId: studentId,
            session: params.session,
            term: params.term,
          );

          results.add(attendance);
        } catch (error) {
          debugPrint(
            'Failed to load attendance for student $studentId: $error',
          );
        }
      }

      return results;
    });

// ==================================================================
// ADMIN RESULTS PARAMS
// ==================================================================

class AdminResultsParams {
  final String schoolId;
  final String? session;
  final String? term;

  const AdminResultsParams({required this.schoolId, this.session, this.term});

  @override
  bool operator ==(Object other) {
    return other is AdminResultsParams &&
        other.schoolId == schoolId &&
        other.session == session &&
        other.term == term;
  }

  @override
  int get hashCode {
    return Object.hash(schoolId, session, term);
  }
}

// ==================================================================
// ADMIN RESULTS PROVIDER
// ==================================================================
//
// GET /api/admin/results
//
// The repository returns AdminResultsResponse.
// The provider exposes only response.results.
// ==================================================================

final adminResultsProvider = FutureProvider.autoDispose
    .family<List<AdminResultModel>, AdminResultsParams>((ref, params) async {
      final repository = ref.read(adminRepositoryProvider);

      final response = await repository.getResultsForSchool(
        schoolId: params.schoolId,
        session: params.session,
        term: params.term,
      );

      return response.results;
    });

// ==================================================================
// ADMIN DASHBOARD DATA
// ==================================================================

class AdminDashboardData {
  final List<AdminTeacherModel> teachers;
  final List<AdminStudentModel> students;
  final List<AdminClassModel> classes;
  final List<AdminSubjectModel> subjects;
  final List<AdminParentModel> parents;

  // ================================================================
  // TRADES
  // ================================================================

  final List<AdminTradeModel> trades;

  // ================================================================
  // DEPARTMENTS
  // ================================================================

  final List<AdminDepartmentModel> departments;

  const AdminDashboardData({
    required this.teachers,
    required this.students,
    required this.classes,
    required this.subjects,
    required this.parents,
    required this.trades,
    required this.departments,
  });

  // ================================================================
  // COUNTS
  // ================================================================

  int get teacherCount => teachers.length;

  int get studentCount => students.length;

  int get classCount => classes.length;

  int get subjectCount => subjects.length;

  int get parentCount => parents.length;

  int get tradeCount => trades.length;

  int get departmentCount => departments.length;

  // ================================================================
  // COPY WITH
  // ================================================================

  AdminDashboardData copyWith({
    List<AdminTeacherModel>? teachers,
    List<AdminStudentModel>? students,
    List<AdminClassModel>? classes,
    List<AdminSubjectModel>? subjects,
    List<AdminParentModel>? parents,
    List<AdminTradeModel>? trades,
    List<AdminDepartmentModel>? departments,
  }) {
    return AdminDashboardData(
      teachers: teachers ?? this.teachers,
      students: students ?? this.students,
      classes: classes ?? this.classes,
      subjects: subjects ?? this.subjects,
      parents: parents ?? this.parents,
      trades: trades ?? this.trades,
      departments: departments ?? this.departments,
    );
  }
}

// ==================================================================
// ADMIN DASHBOARD PROVIDER
// ==================================================================

final adminDashboardProvider =
    AsyncNotifierProvider<AdminDashboardNotifier, AdminDashboardData>(
      AdminDashboardNotifier.new,
    );

// ==================================================================
// ADMIN DASHBOARD NOTIFIER
// ==================================================================

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
      // 0
      repository.getTeachers(),

      // 1
      repository.getStudents(),

      // 2
      repository.getClasses(),

      // 3
      repository.getAdminSubjects(),

      // 4
      repository.getParents(),

      // 5
      repository.getTrades(),

      // 6
      repository.getDepartments(),
    ]);

    return AdminDashboardData(
      teachers: results[0] as List<AdminTeacherModel>,
      students: results[1] as List<AdminStudentModel>,
      classes: results[2] as List<AdminClassModel>,
      subjects: results[3] as List<AdminSubjectModel>,
      parents: results[4] as List<AdminParentModel>,
      trades: results[5] as List<AdminTradeModel>,
      departments: results[6] as List<AdminDepartmentModel>,
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
  // GET STUDENTS FOR SCHOOL
  // ================================================================

  List<AdminStudentModel> getStudentsForSchool(String schoolId) {
    final students = state.value?.students ?? [];

    return students.where((student) => student.schoolId == schoolId).toList();
  }

  // ================================================================
  // GET CLASSES FOR SCHOOL
  // ================================================================

  List<AdminClassModel> getClassesForSchool(String schoolId) {
    final classes = state.value?.classes ?? [];

    return classes
        .where((schoolClass) => schoolClass.schoolId == schoolId)
        .toList();
  }

  // ================================================================
  // GET SUBJECTS FOR SCHOOL
  // ================================================================

  List<AdminSubjectModel> getSubjectsForSchool(String schoolId) {
    final subjects = state.value?.subjects ?? [];

    return subjects.where((subject) => subject.schoolId == schoolId).toList();
  }

  // ================================================================
  // GET TRADES FOR SCHOOL
  // ================================================================

  List<AdminTradeModel> getTradesForSchool(String schoolId) {
    final trades = state.value?.trades ?? [];

    return trades.where((trade) => trade.schoolId == schoolId).toList();
  }

  // ================================================================
  // GET DEPARTMENTS FOR SCHOOL
  // ================================================================

  List<AdminDepartmentModel> getDepartmentsForSchool(String schoolId) {
    final departments = state.value?.departments ?? [];

    return departments
        .where((department) => department.schoolId == schoolId)
        .toList();
  }

  // ================================================================
  // GET PARENTS FOR SCHOOL
  // ================================================================
  //
  // AdminParentModel does NOT currently expose schoolId based on
  // your previous error, so do not filter it using parent.schoolId.
  // ================================================================

  List<AdminParentModel> getParentsForSchool(String schoolId) {
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

      final teacher = await repository.createTeacher(data: data);

      final currentState = state.value;

      if (currentState != null) {
        state = AsyncData(
          currentState.copyWith(teachers: [teacher, ...currentState.teachers]),
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
        final updatedTeachers = currentState.teachers.map((teacher) {
          if (teacher.teacherId == teacherId) {
            return updatedTeacher;
          }

          return teacher;
        }).toList();

        state = AsyncData(currentState.copyWith(teachers: updatedTeachers));
      }

      ref.invalidate(adminTeacherDetailsProvider(teacherId));

      return updatedTeacher;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return null;
    }
  }

  // ================================================================
  // DELETE TEACHER
  // ================================================================

  Future<bool> deleteTeacher({required String teacherId}) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      await repository.deleteTeacher(teacherId: teacherId);

      final currentState = state.value;

      if (currentState != null) {
        state = AsyncData(
          currentState.copyWith(
            teachers: currentState.teachers
                .where((teacher) => teacher.teacherId != teacherId)
                .toList(),
          ),
        );
      }

      ref.invalidate(adminTeacherDetailsProvider(teacherId));

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
          currentState.copyWith(students: [student, ...currentState.students]),
        );
      }

      return student;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      debugPrint('CREATE STUDENT ERROR: $error');

      debugPrintStack(stackTrace: stackTrace);

      rethrow;
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
        final updatedStudents = currentState.students.map((student) {
          if (student.studentId == studentId) {
            return updatedStudent;
          }

          return student;
        }).toList();

        state = AsyncData(currentState.copyWith(students: updatedStudents));
      }

      ref.invalidate(adminStudentDetailsProvider(studentId));

      return updatedStudent;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return null;
    }
  }

  // ================================================================
  // DELETE STUDENT
  // ================================================================

  Future<bool> deleteStudent({required String studentId}) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      await repository.deleteStudent(studentId: studentId);

      final currentState = state.value;

      if (currentState != null) {
        state = AsyncData(
          currentState.copyWith(
            students: currentState.students
                .where((student) => student.studentId != studentId)
                .toList(),
          ),
        );
      }

      ref.invalidate(adminStudentDetailsProvider(studentId));

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
            classes: [schoolClass, ...currentState.classes],
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
          currentState.copyWith(subjects: [subject, ...currentState.subjects]),
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

      // Reload dashboard so the new assignment appears immediately.
      await refresh();

      return true;
    } catch (error, stackTrace) {
      debugPrint('ASSIGN TEACHER ERROR: $error');

      state = AsyncError(error, stackTrace);

      return false;
    }
  }
  // ================================================================
  // GET TEACHERS FOR SUBJECT
  // ================================================================

  Future<List<AdminSubjectTeacherModel>> getTeachersForSubject({
    required String subjectId,
  }) async {
    final repository = ref.read(adminRepositoryProvider);

    return repository.getTeachersForSubject(subjectId: subjectId);
  }

  // ================================================================
  // UNASSIGN TEACHER FROM SUBJECT
  // ================================================================

  Future<bool> unassignTeacherFromSubject({
    required String assignmentId,
  }) async {
    try {
      debugPrint('AssignmentId: $assignmentId');

      final repository = ref.read(adminRepositoryProvider);

      await repository.unassignTeacherFromSubject(assignmentId: assignmentId);

      // Reload dashboard so the assignment disappears immediately.
      await refresh();

      return true;
    } catch (error, stackTrace) {
      debugPrint('UNASSIGN TEACHER ERROR: $error');

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

      final updatedSubject = await repository.updateSubject(
        schoolId: schoolId,
        subjectId: subjectId,
        data: data,
      );

      final currentState = state.value;

      if (currentState != null) {
        final updatedSubjects = currentState.subjects.map((subject) {
          if (subject.subjectId == subjectId && subject.schoolId == schoolId) {
            return subject.copyWith(
              subjectName: updatedSubject.subjectName,
              code: updatedSubject.code,
              type: updatedSubject.type,
              departmentId: updatedSubject.departmentId,
              tradeId: updatedSubject.tradeId,
            );
          }

          return subject;
        }).toList();

        state = AsyncData(currentState.copyWith(subjects: updatedSubjects));
      }

      return updatedSubject;
    } catch (error, stackTrace) {
      debugPrint('UPDATE SUBJECT ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      // Do not convert the state to AsyncError here if this is an
      // action initiated from an already-loaded dashboard.
      rethrow;
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
        state = AsyncData(
          currentState.copyWith(
            subjects: currentState.subjects
                .where((subject) => subject.subjectId != subjectId)
                .toList(),
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
  // PARENT
  // ================================================================

  // ------------------------------------------------
  // GET PARENT BY ID
  // ------------------------------------------------

  Future<AdminParentDetailModel?> getParentById({
    required String parentId,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      return await repository.getParentDetails(parentId: parentId);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return null;
    }
  }

  // ------------------------------------------------
  // UPDATE PARENT
  // ------------------------------------------------

  Future<AdminParentModel?> updateParent({
    required String parentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      final updatedParent = await repository.updateParent(
        parentId: parentId,
        data: data,
      );

      final currentState = state.value;

      if (currentState != null) {
        final updatedParents = currentState.parents.map((parent) {
          if (parent.parentId == parentId) {
            return updatedParent;
          }

          return parent;
        }).toList();

        state = AsyncData(currentState.copyWith(parents: updatedParents));
      }

      ref.invalidate(adminParentDetailsProvider(parentId));

      return updatedParent;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return null;
    }
  }

  // ------------------------------------------------
  // DELETE PARENT
  // ------------------------------------------------

  Future<bool> deleteParent({required String parentId}) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      await repository.deleteParent(parentId: parentId);

      final currentState = state.value;

      if (currentState != null) {
        state = AsyncData(
          currentState.copyWith(
            parents: currentState.parents
                .where((parent) => parent.parentId != parentId)
                .toList(),
          ),
        );
      }

      ref.invalidate(adminParentDetailsProvider(parentId));

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  // ================================================================
  // RESULTS
  // ================================================================

  // ------------------------------------------------
  // GET RESULTS FOR SCHOOL
  // ------------------------------------------------

  Future<List<AdminResultModel>> getResultsForSchool({
    required String schoolId,
    String? session,
    String? term,
  }) async {
    final repository = ref.read(adminRepositoryProvider);

    final response = await repository.getResultsForSchool(
      schoolId: schoolId,
      session: session,
      term: term,
    );

    return response.results;
  }

  // ------------------------------------------------
  // GET SINGLE RESULT
  // ------------------------------------------------

  Future<AdminResultModel?> getResultById({required String resultId}) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      return await repository.getResult(resultId: resultId);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return null;
    }
  }

  // ------------------------------------------------
  // GET STUDENT RESULTS
  // ------------------------------------------------

  Future<AdminResultsResponse> getStudentResults({
    required String studentId,
    required String session,
    required String term,
  }) async {
    final repository = ref.read(adminRepositoryProvider);

    return repository.getStudentResults(
      studentId: studentId,
      session: session,
      term: term,
    );
  }

  // ------------------------------------------------
  // GET CLASS RESULTS
  // ------------------------------------------------

  Future<AdminResultsResponse> getClassResults({
    required String classId,
    required String session,
    required String term,
  }) async {
    final repository = ref.read(adminRepositoryProvider);

    return repository.getClassResults(
      classId: classId,
      session: session,
      term: term,
    );
  }

  // ------------------------------------------------
  // GET SUBJECT RESULTS
  // ------------------------------------------------

  Future<AdminResultsResponse> getSubjectResults({
    required String subjectId,
    required String classId,
    required String session,
    required String term,
  }) async {
    final repository = ref.read(adminRepositoryProvider);

    return repository.getSubjectResults(
      subjectId: subjectId,
      classId: classId,
      session: session,
      term: term,
    );
  }

  // ------------------------------------------------
  // CREATE RESULT
  // ------------------------------------------------

  Future<AdminResultModel?> createResult({
    required String schoolId,
    required CreateAdminResultRequest request,
    String? session,
    String? term,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      final result = await repository.createResult(request);

      ref.invalidate(adminResultDetailsProvider(result.resultId));

      ref.invalidate(
        adminResultsProvider(
          AdminResultsParams(schoolId: schoolId, session: session, term: term),
        ),
      );

      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return null;
    }
  }

  // ================================================================
  // CREATE TEST RESULT
  // ================================================================

  Future<AdminResultModel?> createTestResult({
    required CreateAdminResultRequest request,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      final result = await repository.createTestResult(request);

      ref.invalidate(adminResultDetailsProvider(result.resultId));

      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return null;
    }
  }

  // ================================================================
  // CREATE EXAM RESULT
  // ================================================================

  Future<AdminResultModel?> createExamResult({
    required CreateAdminResultRequest request,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      final result = await repository.createExamResult(request);

      ref.invalidate(adminResultDetailsProvider(result.resultId));

      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return null;
    }
  }

  // ------------------------------------------------
  // UPDATE RESULT
  // ------------------------------------------------

  Future<AdminResultModel?> updateResult({
    required String resultId,
    required UpdateAdminResultRequest request,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      final result = await repository.updateResult(
        resultId: resultId,
        request: request,
      );

      ref.invalidate(adminResultDetailsProvider(resultId));

      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return null;
    }
  }

  // ------------------------------------------------
  // DELETE RESULT
  // ------------------------------------------------

  Future<bool> deleteResult({required String resultId}) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      await repository.deleteResult(resultId: resultId);

      ref.invalidate(adminResultDetailsProvider(resultId));

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  Future<Object?> assignStudentToTrade({required String studentId, required String tradeId}) async {}
}
