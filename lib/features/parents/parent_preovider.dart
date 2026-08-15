import 'package:app/core/network/dio_provider.dart';
import 'package:app/features/parents/data/parent_repository.dart';
import 'package:app/features/parents/data/parents_api.dart';
import 'package:app/features/parents/models/parent_child_model.dart';
import 'package:app/features/parents/models/parent_model.dart';
import 'package:app/features/parents/models/parent_result_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);

  return ParentRepository(
    ParentApi(dioClient),
  );
});

final parentProfileProvider = FutureProvider<ParentModel>((ref) async {
  final repository = ref.read(parentRepositoryProvider);

  return repository.getProfile();
});

final parentChildrenProvider =
    FutureProvider<List<ParentChildModel>>((ref) async {
  final repository = ref.read(parentRepositoryProvider);

  return repository.getChildren();
});

final parentChildProvider =
    FutureProvider.family<ParentChildModel, String>(
  (ref, studentId) async {
    final repository = ref.read(parentRepositoryProvider);

    return repository.getChild(studentId);
  },
);

// ============================================================
// RESULTS PARAMS
// ============================================================

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
  bool operator ==(Object other) {
    return other is ParentResultsParams &&
        other.studentId == studentId &&
        other.session == session &&
        other.term == term;
  }

  @override
  int get hashCode => Object.hash(
        studentId,
        session,
        term,
      );
}

// ============================================================
// CHILD RESULTS
// ============================================================

final parentChildResultsProvider = FutureProvider.family<
    List<ParentResultModel>,
    ({String studentId, String session, String term})>(
  (ref, params) async {
    final repository = ref.read(parentRepositoryProvider);

    return repository.getChildResults(
      params.studentId,
      params.session,
      params.term,
    );
  },
);