import 'package:app/core/network/dio_provider.dart';
import 'package:app/features/admin/data/admin_api.dart';
import 'package:app/features/admin/data/admin_repository.dart';
import 'package:app/features/admin/models/academic_session/admin_academic_session_model.dart';
import 'package:app/features/admin/models/academic_session/admin_academic_session_request_model.dart';
import 'package:app/features/admin/models/academic_term/academic_term_request_model.dart';
import 'package:app/features/admin/models/academic_term/admin_academic_term_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/provider/auth_provider.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  final adminApi = AdminApi(dioClient);

  return AdminRepository(api: adminApi);
});

final adminAcademicSessionProvider =
    AsyncNotifierProvider<
      AdminAcademicSessionNotifier,
      List<AdminAcademicSessionModel>
    >(AdminAcademicSessionNotifier.new);

class AdminAcademicSessionNotifier
    extends AsyncNotifier<List<AdminAcademicSessionModel>> {
  // ================================================================
  // BUILD
  // ================================================================

  @override
  Future<List<AdminAcademicSessionModel>> build() async {
    final user = ref.watch(authProvider).value?.user;

    final schoolId = user?.schoolId;

    if (schoolId == null || schoolId.trim().isEmpty) {
      return [];
    }

    return ref.read(adminRepositoryProvider).getAcademicSessions();
  }

  // ================================================================
  // CREATE
  // ================================================================

  Future<void> createAcademicSession({
    required String session,
    required DateTime startDate,
    required DateTime endDate,
    bool isActive = false,
  }) async {
    final user = ref.read(authProvider).value?.user;
    final schoolId = user?.schoolId;

    if (schoolId == null || schoolId.trim().isEmpty) {
      throw Exception('Admin account is not assigned to a school.');
    }

    if (session.trim().isEmpty) {
      throw Exception('Academic year name is required.');
    }

    if (endDate.isBefore(startDate)) {
      throw Exception('End date cannot be before start date.');
    }

    final request = AdminAcademicSessionRequestModel(
      session: session.trim(),
      startDate: startDate,
      endDate: endDate,
    );

    await ref
        .read(adminRepositoryProvider)
        .createAcademicSession(data: request);

    await refresh();
  }

  // ================================================================
  // UPDATE
  // ================================================================

  Future<void> updateAcademicSession({
    required String sessionId,
    required String session,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final user = ref.read(authProvider).value?.user;
    final schoolId = user?.schoolId;

    if (schoolId == null || schoolId.trim().isEmpty) {
      throw Exception('Admin account is not assigned to a school.');
    }

    if (session.trim().isEmpty) {
      throw Exception('Academic year name is required.');
    }

    if (endDate.isBefore(startDate)) {
      throw Exception('End date cannot be before start date.');
    }

    final request = AdminAcademicSessionRequestModel(
      session: session.trim(),
      startDate: startDate,
      endDate: endDate,
    );

    await ref
        .read(adminRepositoryProvider)
        .updateAcademicSession(sessionId: sessionId, data: request);

    await refresh();
  }

  // ================================================================
  // DELETE
  // ================================================================

  Future<void> deleteAcademicSession({required String sessionId}) async {
    await ref
        .read(adminRepositoryProvider)
        .deleteAcademicSession(sessionId: sessionId);

    await refresh();
  }

  // ================================================================
  // SET ACTIVE
  // ================================================================

  Future<void> setActiveAcademicSession({required String sessionId}) async {
    await ref
        .read(adminRepositoryProvider)
        .setActiveAcademicSession(sessionId: sessionId);

    await refresh();
  }

  // ================================================================
  // CREATE ACADEMIC TERM
  // ================================================================

  Future<AdminAcademicTermModel> createAcademicTerm({
    required String academicSessionId,
    required String term,
    required DateTime startDate,
    required DateTime endDate,
    bool isCurrent = false,
  }) async {
    if (term.trim().isEmpty) {
      throw Exception('Term name is required.');
    }

    if (endDate.isBefore(startDate)) {
      throw Exception('End date cannot be before start date.');
    }

    final request = AdminAcademicTermRequestModel(
      academicSessionId: academicSessionId,
      term: term.trim(),
      startDate: startDate,
      endDate: endDate,
      isCurrent: isCurrent,
    );

    return await ref
        .read(adminRepositoryProvider)
        .createAcademicTerm(data: request);
  }

  // ================================================================
  // GET ALL TERMS FOR A SESSION
  // ================================================================

  Future<List<AdminAcademicTermModel>> getAcademicTerms({
    required String academicSessionId,
  }) async {
    return await ref
        .read(adminRepositoryProvider)
        .getAcademicTerms(academicSessionId: academicSessionId);
  }

  // ================================================================
  // GET PARTICULAR TERM
  // ================================================================

  Future<AdminAcademicTermModel> getAcademicTerm({
    required String termId,
  }) async {
    return await ref
        .read(adminRepositoryProvider)
        .getAcademicTerm(termId: termId);
  }

  // ================================================================
  // UPDATE ACADEMIC TERM
  // ================================================================

  Future<AdminAcademicTermModel> updateAcademicTerm({
    required String termId,
    required String academicSessionId,
    required String term,
    required DateTime startDate,
    required DateTime endDate,
    bool isCurrent = false,
  }) async {
    if (term.trim().isEmpty) {
      throw Exception('Term name is required.');
    }

    if (endDate.isBefore(startDate)) {
      throw Exception('End date cannot be before start date.');
    }

    final request = AdminAcademicTermRequestModel(
      academicSessionId: academicSessionId,
      term: term.trim(),
      startDate: startDate,
      endDate: endDate,
      isCurrent: isCurrent,
    );

    return await ref
        .read(adminRepositoryProvider)
        .updateAcademicTerm(termId: termId, data: request);
  }

  // ================================================================
  // DELETE ACADEMIC TERM
  // ================================================================

  Future<void> deleteAcademicTerm({required String termId}) async {
    await ref.read(adminRepositoryProvider).deleteAcademicTerm(termId: termId);
  }

  // ================================================================
  // REFRESH
  // ================================================================

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  // ================================================================
  // CURRENT SESSION
  // ================================================================

  AdminAcademicSessionModel? get currentAcademicSession {
    final sessions = state.valueOrNull ?? [];

    for (final session in sessions) {
      if (session.isCurrent) {
        return session;
      }
    }

    return null;
  }
}
