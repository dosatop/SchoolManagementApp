import 'package:app/core/network/dio_provider.dart';
import 'package:app/features/teacher/data/teachers_api.dart';
import 'package:app/features/teacher/data/teachers_repository.dart';
import 'package:app/features/teacher/models/teacher_assignment_params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ================================================================
// TEACHER API PROVIDER
// ================================================================

final teacherApiProvider = Provider<TeacherApi>((ref) {
  final dioClient = ref.read(dioClientProvider);

  return TeacherApi(dioClient);
});

// ================================================================
// TEACHER REPOSITORY PROVIDER
// ================================================================

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  final api = ref.read(teacherApiProvider);

  return TeacherRepository(api: api);
});

final teacherStudentsProvider = FutureProvider.family<dynamic, String?>((
  ref,
  classId,
) async {
  final repository = ref.read(teacherRepositoryProvider);

  return repository.getTeacherStudents(classId: classId);
});

// ===================================================================
// GET TEACHER STUDENT DETAILS
// ===================================================================

final teacherStudentDetailsProvider = FutureProvider.autoDispose
    .family<dynamic, String>((ref, studentId) async {
      final repository = ref.read(teacherRepositoryProvider);

      return repository.getStudentDetails(studentId: studentId);
    });

// ================================================================
// TEACHER ASSIGNMENT DETAILS PROVIDER
// ================================================================

final teacherAssignmentDetailsProvider = FutureProvider.autoDispose
    .family<dynamic, String>((ref, assignmentId) async {
      final repository = ref.read(teacherRepositoryProvider);

      return repository.getAssignment(assignmentId: assignmentId);
    });

// ================================================================
// TEACHER ACTION PROVIDER
// ================================================================

final teachersProvider = AsyncNotifierProvider<TeacherNotifier, void>(
  TeacherNotifier.new,
);

// ================================================================
// TEACHER NOTIFIER
// ================================================================

class TeacherNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  // ================================================================
  // TEACHER PROFILE
  // ================================================================

  Future<bool> getTeacherProfile() async {
    try {
      final repository = ref.read(teacherRepositoryProvider);

      await repository.getTeacherProfile();

      ref.invalidate(teacherProfileProvider);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  // ================================================================
  // TEACHER CLASSES
  // ================================================================

  Future<bool> getTeacherClasses() async {
    try {
      final repository = ref.read(teacherRepositoryProvider);

      await repository.getTeacherClasses();

      ref.invalidate(teacherClassesProvider);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  // ================================================================
  // TEACHER SUBJECTS
  // ================================================================

  Future<bool> getTeacherSubjects() async {
    try {
      final repository = ref.read(teacherRepositoryProvider);

      await repository.getTeacherSubjects();

      ref.invalidate(teacherSubjectsProvider);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  // ================================================================
  // TEACHER STUDENTS
  // ================================================================

  Future<bool> getTeacherStudents({String? classId}) async {
    try {
      final repository = ref.read(teacherRepositoryProvider);

      await repository.getTeacherStudents(classId: classId);

      ref.invalidate(teacherStudentsProvider);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  // ================================================================
  // GET TEACHER RESULTS
  // ================================================================

  Future<bool> getTeacherResults({
    String? studentId,
    String? classId,
    String? subjectId,
    String? session,
    String? term,
  }) async {
    try {
      final repository = ref.read(teacherRepositoryProvider);

      await repository.getTeacherResults(
        studentId: studentId,
        classId: classId,
        subjectId: subjectId,
        session: session,
        term: term,
      );

      ref.invalidate(
        teacherResultsProvider(
          TeacherResultsFilter(
            studentId: studentId,
            classId: classId,
            subjectId: subjectId,
            session: session,
            term: term,
          ),
        ),
      );

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  // ================================================================
  // UPLOAD TEST RESULT
  // ================================================================

  Future<bool> uploadTestResult({
    required String studentId,
    required String classId,
    required String subjectId,
    required double testScore,
    String? remark,
  }) async {
    try {
      final repository = ref.read(teacherRepositoryProvider);

      await repository.uploadTestResult(
        studentId: studentId,
        classId: classId,
        subjectId: subjectId,
        testScore: testScore,
        remark: remark,
      );

      ref.invalidate(teacherResultsProvider);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  // ================================================================
  // UPLOAD EXAM RESULT
  // ================================================================

  Future<bool> uploadExamResult({
    required String studentId,
    required String classId,
    required String subjectId,
    required double examScore,
    String? remark,
  }) async {
    try {
      final repository = ref.read(teacherRepositoryProvider);

      await repository.uploadExamResult(
        studentId: studentId,
        classId: classId,
        subjectId: subjectId,
        examScore: examScore,
        remark: remark,
      );

      ref.invalidate(teacherResultsProvider);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  // ================================================================
  // UPLOAD COMPLETE RESULT
  // ================================================================

  Future<bool> uploadResult({
    required String studentId,
    required String classId,
    required String subjectId,
    required double testScore,
    required double examScore,
    String? remark,
  }) async {
    try {
      final repository = ref.read(teacherRepositoryProvider);

      await repository.uploadResult(
        studentId: studentId,
        classId: classId,
        subjectId: subjectId,
        testScore: testScore,
        examScore: examScore,
        remark: remark,
      );

      ref.invalidate(teacherResultsProvider);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  // ================================================================
  // UPDATE TEST RESULT
  // ================================================================

  Future<bool> updateTestResult({
    required String resultId,
    required double testScore,
    String? remark,
  }) async {
    try {
      final repository = ref.read(teacherRepositoryProvider);

      await repository.updateTestResult(
        resultId: resultId,
        testScore: testScore,
        remark: remark,
      );

      ref.invalidate(teacherResultsProvider);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  // ================================================================
  // UPDATE EXAM RESULT
  // ================================================================

  Future<bool> updateExamResult({
    required String resultId,
    required double examScore,
    String? remark,
  }) async {
    try {
      final repository = ref.read(teacherRepositoryProvider);

      await repository.updateExamResult(
        resultId: resultId,
        examScore: examScore,
        remark: remark,
      );

      ref.invalidate(teacherResultsProvider);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  // ================================================================
  // UPDATE COMPLETE RESULT
  // ================================================================

  Future<bool> updateResult({
    required String resultId,
    required double testScore,
    required double examScore,
    String? remark,
  }) async {
    try {
      final repository = ref.read(teacherRepositoryProvider);

      await repository.updateResult(
        resultId: resultId,
        testScore: testScore,
        examScore: examScore,
        remark: remark,
      );

      ref.invalidate(teacherResultsProvider);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  // ================================================================
  // CREATE ASSIGNMENT
  // ================================================================

  Future<bool> createAssignment({
    required String classId,
    required String subjectId,
    required String title,
    String? description,
    String? attachmentUrl,
    String? dueDate,
  }) async {
    try {
      final repository = ref.read(teacherRepositoryProvider);

      await repository.createAssignment(
        classId: classId,
        subjectId: subjectId,
        title: title,
        description: description,
        attachmentUrl: attachmentUrl,
        dueDate: dueDate,
      );

      ref.invalidate(teacherAssignmentsProvider);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  // ================================================================
  // UPDATE ASSIGNMENT
  // ================================================================

  Future<bool> updateAssignment({
    required String assignmentId,
    required String classId,
    required String subjectId,
    required String title,
    String? description,
    String? attachmentUrl,
    String? dueDate,
    required bool isPublished,
  }) async {
    try {
      final repository = ref.read(teacherRepositoryProvider);

      await repository.updateAssignment(
        assignmentId: assignmentId,
        classId: classId,
        subjectId: subjectId,
        title: title,
        description: description,
        attachmentUrl: attachmentUrl,
        dueDate: dueDate,
        isPublished: isPublished,
      );

      ref.invalidate(teacherAssignmentsProvider);
      ref.invalidate(teacherAssignmentProvider(assignmentId));

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  // ================================================================
  // DELETE ASSIGNMENT
  // ================================================================

  Future<bool> deleteAssignment({required String assignmentId}) async {
    try {
      final repository = ref.read(teacherRepositoryProvider);

      await repository.deleteAssignment(assignmentId: assignmentId);

      ref.invalidate(teacherAssignmentsProvider);
      ref.invalidate(teacherAssignmentProvider(assignmentId));

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  // ================================================================
  // CREATE ATTENDANCE
  // ================================================================

  Future<bool> createAttendance({
    required String studentId,
    required String classId,
    String? subjectId,
    required String attendanceDate,
    required String status,
    String? remarks,
  }) async {
    try {
      final repository = ref.read(teacherRepositoryProvider);

      await repository.createAttendance(
        studentId: studentId,
        classId: classId,
        subjectId: subjectId,
        attendanceDate: attendanceDate,
        status: status,
        remarks: remarks,
      );

      ref.invalidate(teacherAttendanceProvider);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  // ================================================================
  // CREATE BULK ATTENDANCE
  // ================================================================

  // ================================================================
  // CREATE BULK CLASS ATTENDANCE
  // ================================================================
  //
  // Used when the teacher is the class teacher.
  // SubjectId is always null for this type of attendance.
  //

  Future<bool> createBulkAttendance({
    required String classId,
    required String attendanceDate,
    required List<Map<String, dynamic>> students,
  }) async {
    try {
      state = const AsyncLoading();

      final repository = ref.read(teacherRepositoryProvider);

      await repository.createBulkAttendance(
        classId: classId,
        attendanceDate: attendanceDate,
        students: students,
      );

      // Refresh general attendance
      ref.invalidate(teacherAttendanceProvider);

      // Refresh class attendance
      ref.invalidate(
        teacherClassAttendanceProvider(
          TeacherClassAttendanceParams(
            classId: classId,
            subjectId: null,
            date: attendanceDate,
          ),
        ),
      );

      state = const AsyncData(null);

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }

  // ================================================================
  // DELETE ATTENDANCE
  // ================================================================

  Future<bool> deleteAttendance({required String attendanceId}) async {
    try {
      final repository = ref.read(teacherRepositoryProvider);

      await repository.deleteAttendance(attendanceId: attendanceId);

      ref.invalidate(teacherAttendanceProvider);
      ref.invalidate(teacherAttendanceRecordProvider(attendanceId));

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);

      return false;
    }
  }
}

// ===================================================================
// GET TEACHER PROFILE PROVIDER
// ===================================================================

final teacherProfileProvider = FutureProvider.autoDispose<dynamic>((ref) async {
  final repository = ref.read(teacherRepositoryProvider);

  return repository.getTeacherProfile();
});

// ===================================================================
// GET TEACHER CLASSES PROVIDER
// ===================================================================

final teacherClassesProvider = FutureProvider.autoDispose<dynamic>((ref) async {
  final repository = ref.read(teacherRepositoryProvider);

  return repository.getTeacherClasses();
});

// ===================================================================
// GET TEACHER SUBJECTS PROVIDER
// ===================================================================

final teacherSubjectsProvider = FutureProvider.autoDispose<dynamic>((
  ref,
) async {
  final repository = ref.read(teacherRepositoryProvider);

  return repository.getTeacherSubjects();
});

// ===================================================================
// GET TEACHER RESULTS PROVIDER
// ===================================================================

final teacherResultsProvider = FutureProvider.autoDispose
    .family<dynamic, TeacherResultsFilter>((ref, filter) async {
      final repository = ref.read(teacherRepositoryProvider);

      return repository.getTeacherResults(
        studentId: filter.studentId,
        classId: filter.classId,
        subjectId: filter.subjectId,
        session: filter.session,
        term: filter.term,
      );
    });

// ===================================================================
// TEACHER RESULTS FILTER
// ===================================================================

class TeacherResultsFilter {
  final String? studentId;
  final String? classId;
  final String? subjectId;
  final String? session;
  final String? term;

  const TeacherResultsFilter({
    this.studentId,
    this.classId,
    this.subjectId,
    this.session,
    this.term,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TeacherResultsFilter &&
        other.studentId == studentId &&
        other.classId == classId &&
        other.subjectId == subjectId &&
        other.session == session &&
        other.term == term;
  }

  @override
  int get hashCode => Object.hash(studentId, classId, subjectId, session, term);
}

// ===================================================================
// GET TEACHER ASSIGNMENTS PROVIDER
// ===================================================================

final teacherAssignmentsProvider = FutureProvider.autoDispose<dynamic>((
  ref,
) async {
  final repository = ref.read(teacherRepositoryProvider);

  return repository.getAssignments();
});

final teacherClassAssignmentsProvider = FutureProvider.autoDispose
    .family<dynamic, TeacherAssignmentsParams>((ref, params) async {
      final repository = ref.read(teacherRepositoryProvider);

      return repository.getAssignments(
        classId: params.classId,
        subjectId: params.subjectId,
        session: params.session,
        term: params.term,
      );
    });

// ===================================================================
// GET SINGLE ASSIGNMENT PROVIDER
// ===================================================================

final teacherAssignmentProvider = FutureProvider.autoDispose
    .family<dynamic, String>((ref, assignmentId) async {
      final repository = ref.read(teacherRepositoryProvider);

      return repository.getAssignment(assignmentId: assignmentId);
    });

// ===================================================================
// GET TEACHER ATTENDANCE PROVIDER
// ===================================================================

final teacherAttendanceProvider = FutureProvider.autoDispose<dynamic>((
  ref,
) async {
  final repository = ref.read(teacherRepositoryProvider);

  return repository.getAttendance();
});

class TeacherClassAttendanceParams {
  final String classId;
  final String? subjectId;
  final String? date;
  final String? session;
  final String? term;

  const TeacherClassAttendanceParams({
    required this.classId,
    this.subjectId,
    this.date,
    this.session,
    this.term,
  });

  @override
  bool operator ==(Object other) {
    return other is TeacherClassAttendanceParams &&
        other.classId == classId &&
        other.subjectId == subjectId &&
        other.date == date &&
        other.session == session &&
        other.term == term;
  }

  @override
  int get hashCode {
    return Object.hash(classId, subjectId, date, session, term);
  }
}

final teacherClassAttendanceProvider = FutureProvider.autoDispose
    .family<dynamic, TeacherClassAttendanceParams>((ref, params) async {
      final repository = ref.read(teacherRepositoryProvider);

      return repository.getAttendance(
        classId: params.classId,
        subjectId: params.subjectId,
        date: params.date,
        session: params.session,
        term: params.term,
      );
    });

// ===================================================================
// GET SINGLE ATTENDANCE RECORD PROVIDER
// ===================================================================

final teacherAttendanceRecordProvider = FutureProvider.autoDispose
    .family<dynamic, String>((ref, attendanceId) async {
      final repository = ref.read(teacherRepositoryProvider);

      return repository.getAttendanceRecord(attendanceId: attendanceId);
    });
