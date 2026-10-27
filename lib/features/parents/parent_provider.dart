import 'package:app/core/network/dio_provider.dart';
import 'package:app/features/parents/data/parent_repository.dart';
import 'package:app/features/parents/data/parents_api.dart';
import 'package:app/features/parents/models/parent_child_model.dart';
import 'package:app/features/parents/models/parent_model.dart';
import 'package:app/features/parents/models/parent_result_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==================================================================
// REPOSITORY + API
// ==================================================================

final parentApiProvider = Provider<ParentApi>((ref) {
  return ParentApi(ref.read(dioClientProvider));
});

final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  return ParentRepository(ref.read(parentApiProvider));
});

// ==================================================================
// PROFILE + CHILDREN
// ==================================================================
// autoDispose so a logout → login as a different parent never shows
// the previous parent's children from cache.

final parentProfileProvider = FutureProvider.autoDispose<ParentModel>((
  ref,
) async {
  return ref.read(parentRepositoryProvider).getProfile();
});

/// Raw profile JSON for the profile page (fullName, email,
/// phoneNumber, schoolName, childrenCount).
final parentProfileDataProvider = FutureProvider.autoDispose<dynamic>((ref) {
  return ref.read(parentRepositoryProvider).getProfileData();
});

final parentChildrenProvider =
    FutureProvider.autoDispose<List<ParentChildModel>>((ref) async {
      return ref.read(parentRepositoryProvider).getChildren();
    });

final parentChildProvider = FutureProvider.autoDispose
    .family<ParentChildModel, String>((ref, studentId) async {
      return ref.read(parentRepositoryProvider).getChild(studentId);
    });

// ==================================================================
// CHILD + TERM PARAMS
// ==================================================================
// Leave session/term null for the school's current session and term.
// Value-equal so the same params reuse the same provider.

class ParentChildTermParams {
  final String studentId;
  final String? session;
  final String? term;

  const ParentChildTermParams(this.studentId, {this.session, this.term});

  @override
  bool operator ==(Object other) =>
      other is ParentChildTermParams &&
      other.studentId == studentId &&
      other.session == session &&
      other.term == term;

  @override
  int get hashCode => Object.hash(studentId, session, term);
}

// ==================================================================
// CHILD DATA (raw JSON — pages read it with tolerant helpers)
// ==================================================================

final parentChildClassProvider = FutureProvider.autoDispose
    .family<dynamic, String>((ref, studentId) {
      return ref.read(parentRepositoryProvider).getChildClass(studentId);
    });

final parentChildSubjectsProvider = FutureProvider.autoDispose
    .family<dynamic, String>((ref, studentId) {
      return ref.read(parentRepositoryProvider).getChildSubjects(studentId);
    });

final parentChildResultsDataProvider = FutureProvider.autoDispose
    .family<dynamic, ParentChildTermParams>((ref, p) {
      return ref
          .read(parentRepositoryProvider)
          .getChildResultsData(p.studentId, session: p.session, term: p.term);
    });

final parentChildAttendanceProvider = FutureProvider.autoDispose
    .family<dynamic, ParentChildTermParams>((ref, p) {
      return ref
          .read(parentRepositoryProvider)
          .getChildAttendance(p.studentId, session: p.session, term: p.term);
    });

final parentChildAssignmentsProvider = FutureProvider.autoDispose
    .family<dynamic, ParentChildTermParams>((ref, p) {
      return ref
          .read(parentRepositoryProvider)
          .getChildAssignments(p.studentId, session: p.session, term: p.term);
    });

final parentChildAssignmentProvider = FutureProvider.autoDispose
    .family<dynamic, ({String studentId, String assignmentId})>((ref, p) {
      return ref
          .read(parentRepositoryProvider)
          .getChildAssignment(p.studentId, p.assignmentId);
    });

// ==================================================================
// LEGACY: typed results (kept so existing code still compiles)
// ==================================================================

class ParentResultsParams {
  final String studentId;
  final String session;
  final String term;

  const ParentResultsParams({
    required this.studentId,
    required this.session,
    required this.term,
  });

  @override
  bool operator ==(Object other) =>
      other is ParentResultsParams &&
      other.studentId == studentId &&
      other.session == session &&
      other.term == term;

  @override
  int get hashCode => Object.hash(studentId, session, term);
}

final parentChildResultsProvider = FutureProvider.autoDispose
    .family<
      List<ParentResultModel>,
      ({String studentId, String session, String term})
    >((ref, params) async {
      return ref
          .read(parentRepositoryProvider)
          .getChildResults(params.studentId, params.session, params.term);
    });