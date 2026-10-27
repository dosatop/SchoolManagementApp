import 'package:app/core/network/dio_provider.dart';
import 'package:app/features/students/data/student_api.dart';
import 'package:app/features/students/data/student_repository.dart';
import 'package:app/features/students/models/student_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==================================================================
// API + REPOSITORY
// ==================================================================

final studentApiProvider = Provider<StudentApi>((ref) {
  return StudentApi(ref.read(dioClientProvider));
});

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(api: ref.read(studentApiProvider));
});

// ==================================================================
// PROFILE
// ==================================================================

final studentProfileProvider =
    AsyncNotifierProvider<StudentProfileNotifier, StudentModel>(
      StudentProfileNotifier.new,
    );

class StudentProfileNotifier extends AsyncNotifier<StudentModel> {
  @override
  Future<StudentModel> build() {
    return ref.read(studentRepositoryProvider).getStudentProfile();
  }

  /// Reloads the profile, keeping the current data on screen while
  /// loading. Throws on failure so pull-to-refresh can finish.
  Future<void> refresh() async {
    state = const AsyncLoading<StudentModel>().copyWithPrevious(state);

    state = await AsyncValue.guard(
      () => ref.read(studentRepositoryProvider).getStudentProfile(),
    );

    if (state.hasError) {
      throw state.error!;
    }
  }
}

// ==================================================================
// SESSION + TERM PARAMS
// ==================================================================
// Leave session/term null to use the school's CURRENT session and
// term (needs the backend change that makes them optional).
//
// Value-equal, so the same params reuse the same provider instead of
// refetching on every rebuild.

class StudentTermParams {
  final String? session;
  final String? term;

  const StudentTermParams({this.session, this.term});

  /// The school's current session and term.
  static const current = StudentTermParams();

  @override
  bool operator ==(Object other) =>
      other is StudentTermParams &&
      other.session == session &&
      other.term == term;

  @override
  int get hashCode => Object.hash(session, term);
}

// ==================================================================
// CLASS
// ==================================================================

final studentClassProvider = FutureProvider.autoDispose<dynamic>((ref) {
  return ref.read(studentRepositoryProvider).getStudentClass();
});

// ==================================================================
// SUBJECTS
// ==================================================================

final studentSubjectsProvider = FutureProvider.autoDispose<dynamic>((ref) {
  return ref.read(studentRepositoryProvider).getStudentSubjects();
});

// ==================================================================
// RESULTS
// ==================================================================

final studentResultsProvider = FutureProvider.autoDispose
    .family<dynamic, StudentTermParams>((ref, params) {
      return ref
          .read(studentRepositoryProvider)
          .getStudentResults(session: params.session, term: params.term);
    });

// ==================================================================
// ATTENDANCE
// ==================================================================

final studentAttendanceProvider = FutureProvider.autoDispose
    .family<dynamic, StudentTermParams>((ref, params) {
      return ref
          .read(studentRepositoryProvider)
          .getStudentAttendance(session: params.session, term: params.term);
    });

// ==================================================================
// ASSIGNMENTS
// ==================================================================

final studentAssignmentsProvider = FutureProvider.autoDispose
    .family<dynamic, StudentTermParams>((ref, params) {
      return ref
          .read(studentRepositoryProvider)
          .getStudentAssignments(session: params.session, term: params.term);
    });

// ==================================================================
// SINGLE ASSIGNMENT
// ==================================================================

final studentAssignmentProvider = FutureProvider.autoDispose
    .family<dynamic, String>((ref, assignmentId) {
      return ref
          .read(studentRepositoryProvider)
          .getStudentAssignment(assignmentId: assignmentId);
    });

// ==================================================================
// SUBMIT ASSIGNMENT (action)
// ==================================================================
// Returns null on success, or an error message to show the student.

final studentActionsProvider = Provider<StudentActions>(StudentActions.new);

class StudentActions {
  StudentActions(this._ref);

  final Ref _ref;

  Future<String?> submitAssignment({
    required String assignmentId,
    String? submissionText,
    String? attachmentUrl,
  }) async {
    final hasText = submissionText?.trim().isNotEmpty ?? false;
    final hasFile = attachmentUrl?.trim().isNotEmpty ?? false;

    if (!hasText && !hasFile) {
      return 'Please add your answer or an attachment.';
    }

    try {
      await _ref
          .read(studentRepositoryProvider)
          .submitAssignment(
            assignmentId: assignmentId,
            submissionText: submissionText,
            attachmentUrl: attachmentUrl,
          );

      // Refresh so the submitted status shows everywhere.
      _ref.invalidate(studentAssignmentProvider(assignmentId));
      _ref.invalidate(studentAssignmentsProvider);

      return null;
    } catch (e) {
      return _message(e);
    }
  }

  String _message(Object error) {
    try {
      final data = (error as dynamic).response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    } catch (_) {}

    return 'Something went wrong. Please try again.';
  }
}