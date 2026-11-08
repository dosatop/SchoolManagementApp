import 'package:app/core/network/dio_provider.dart';
import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:app/features/super_admin/data/super_admin_api.dart';
import 'package:app/features/super_admin/data/super_admin_repository.dart';
import 'package:app/features/super_admin/models/create_school_request.dart';
import 'package:app/features/super_admin/models/school_model.dart';
import 'package:app/features/super_admin/models/school_people_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ====================================================================
// REPOSITORY
// ====================================================================

final superAdminRepositoryProvider = Provider<SuperAdminRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);

  final api = SuperAdminApi(dioClient);

  return SuperAdminRepository(api: api);
});

// ====================================================================
// SCHOOLS
// ====================================================================

final superAdminProvider =
    AsyncNotifierProvider<SuperAdminNotifier, List<SchoolModel>>(
      SuperAdminNotifier.new,
    );

class SuperAdminNotifier extends AsyncNotifier<List<SchoolModel>> {
  // Loads as soon as something watches it. Only a super admin ever
  // calls /api/schools.
  @override
  Future<List<SchoolModel>> build() async {
    if (!signedInAs(ref, 'SuperAdmin')) return [];

    return ref.read(superAdminRepositoryProvider).getSchools();
  }

  // Refresh — keeps the current list on screen while reloading.
  Future<List<SchoolModel>> getSchools() async {
    state = const AsyncLoading<List<SchoolModel>>().copyWithPrevious(state);

    try {
      final schools = await ref.read(superAdminRepositoryProvider).getSchools();

      state = AsyncData(schools);

      return schools;
    } catch (error, stackTrace) {
      state = AsyncError<List<SchoolModel>>(
        error,
        stackTrace,
      ).copyWithPrevious(state);

      return state.valueOrNull ?? [];
    }
  }

  // Doesn't touch the list while saving; reloads it afterwards.
  Future<String?> createSchool(CreateSchoolRequest request) async {
    try {
      await ref.read(superAdminRepositoryProvider).createSchool(request);
    } catch (error) {
      return schoolPeopleError(error);
    }

    await getSchools();

    return null;
  }
}

// ====================================================================
// SCHOOL TEACHERS / STUDENTS / CLASSES
// ====================================================================
// One per school, auto-disposed when the page closes.
// Guarded: never calls the API unless signed in as SuperAdmin.

final schoolTeachersProvider = FutureProvider.autoDispose
    .family<List<SchoolTeacher>, String>((ref, schoolId) async {
      if (!signedInAs(ref, 'SuperAdmin')) return const [];
      return ref.read(superAdminRepositoryProvider).getSchoolTeachers(schoolId);
    });

final schoolStudentsProvider = FutureProvider.autoDispose
    .family<List<SchoolStudent>, String>((ref, schoolId) async {
      if (!signedInAs(ref, 'SuperAdmin')) return const [];
      return ref.read(superAdminRepositoryProvider).getSchoolStudents(schoolId);
    });

final schoolClassesProvider = FutureProvider.autoDispose
    .family<List<SchoolClass>, String>((ref, schoolId) async {
      if (!signedInAs(ref, 'SuperAdmin')) return const [];
      return ref.read(superAdminRepositoryProvider).getSchoolClasses(schoolId);
    });

final schoolAdminAccountsProvider = FutureProvider.autoDispose
    .family<List<SchoolAdmin>, String>((ref, schoolId) async {
      if (!signedInAs(ref, 'SuperAdmin')) return const [];
      return ref
          .read(superAdminRepositoryProvider)
          .getSchoolAdminAccounts(schoolId);
    });

final schoolSubjectsProvider = FutureProvider.autoDispose
    .family<List<SchoolSubject>, String>((ref, schoolId) async {
      if (!signedInAs(ref, 'SuperAdmin')) return const [];
      return ref.read(superAdminRepositoryProvider).getSchoolSubjects(schoolId);
    });

/// Departments + trades (with their subjects) for the Add student form.
final schoolFormOptionsProvider = FutureProvider.autoDispose
    .family<SchoolFormOptions, String>((ref, schoolId) async {
      if (!signedInAs(ref, 'SuperAdmin')) return SchoolFormOptions.empty;
      return ref
          .read(superAdminRepositoryProvider)
          .getSchoolFormOptions(schoolId);
    });

// ====================================================================
// CREATE ACTIONS
// ====================================================================
// Each returns null on success, or a message to show.
// On success the affected lists (and the school counts on the
// dashboard / management page) reload automatically.

final schoolPeopleActionsProvider = Provider<SchoolPeopleActions>(
  SchoolPeopleActions.new,
);

class SchoolPeopleActions {
  SchoolPeopleActions(this._ref);

  final Ref _ref;

  SuperAdminRepository get _repo => _ref.read(superAdminRepositoryProvider);

  Future<String?> createTeacher(
    String schoolId, {
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      await _repo.createSchoolTeacher(
        schoolId,
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
      );
    } catch (error) {
      return schoolPeopleError(error);
    }

    _ref.invalidate(schoolTeachersProvider(schoolId));
    _refreshSchools();
    return null;
  }

  Future<String?> createStudent(
    String schoolId, {
    required String fullName,
    required String email,
    required String password,
    required String classId,
    String? phoneNumber,
    String? studentNumber,
    String? departmentId,
    String? tradeId,
    String? tradeSubjectId,
  }) async {
    try {
      await _repo.createSchoolStudent(
        schoolId,
        fullName: fullName,
        email: email,
        password: password,
        classId: classId,
        phoneNumber: phoneNumber,
        studentNumber: studentNumber,
        departmentId: departmentId,
        tradeId: tradeId,
        tradeSubjectId: tradeSubjectId,
      );
    } catch (error) {
      return schoolPeopleError(error);
    }

    _ref.invalidate(schoolStudentsProvider(schoolId));
    _ref.invalidate(schoolClassesProvider(schoolId)); // student counts
    _refreshSchools();
    return null;
  }

  Future<String?> createClass(
    String schoolId, {
    required String name,
    int? level,
  }) async {
    try {
      await _repo.createSchoolClass(schoolId, name: name, level: level);
    } catch (error) {
      return schoolPeopleError(error);
    }

    _ref.invalidate(schoolClassesProvider(schoolId));
    _refreshSchools();
    return null;
  }

  // ================================================================
  // EDIT / DELETE (SuperAdminController)
  // ================================================================

  Future<String?> updateTeacher(
    String schoolId, {
    required String teacherId,
    required String fullName,
    required String email,
    String? phoneNumber,
    String? newPassword,
  }) => _run(
    () => _repo.updateSchoolTeacher(
      schoolId,
      teacherId,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      newPassword: newPassword,
    ),
    () {
      _ref.invalidate(schoolTeachersProvider(schoolId));
      _ref.invalidate(schoolClassesProvider(schoolId)); // teacher names
    },
  );

  Future<String?> deleteTeacher(
    String schoolId, {
    required String teacherId,
  }) => _run(() => _repo.deleteSchoolTeacher(schoolId, teacherId), () {
    _ref.invalidate(schoolTeachersProvider(schoolId));
    _ref.invalidate(schoolClassesProvider(schoolId));
    _refreshSchools();
  });

  Future<String?> updateStudent(
    String schoolId, {
    required String studentId,
    required String fullName,
    required String email,
    required String studentNumber,
    required String classId,
    String? phoneNumber,
    String? newPassword,
    String? departmentId,
    String? tradeId,
    String? tradeSubjectId,
  }) => _run(
    () => _repo.updateSchoolStudent(
      schoolId,
      studentId,
      fullName: fullName,
      email: email,
      studentNumber: studentNumber,
      classId: classId,
      phoneNumber: phoneNumber,
      newPassword: newPassword,
      departmentId: departmentId,
      tradeId: tradeId,
      tradeSubjectId: tradeSubjectId,
    ),
    () {
      _ref.invalidate(schoolStudentsProvider(schoolId));
      _ref.invalidate(schoolClassesProvider(schoolId)); // class moved
    },
  );

  Future<String?> deleteStudent(
    String schoolId, {
    required String studentId,
  }) => _run(() => _repo.deleteSchoolStudent(schoolId, studentId), () {
    _ref.invalidate(schoolStudentsProvider(schoolId));
    _ref.invalidate(schoolClassesProvider(schoolId));
    _refreshSchools();
  });

  Future<String?> updateClass(
    String schoolId, {
    required String classId,
    required String name,
  }) => _run(() => _repo.updateSchoolClass(schoolId, classId, name: name), () {
    _ref.invalidate(schoolClassesProvider(schoolId));
    _ref.invalidate(schoolStudentsProvider(schoolId)); // class names
    _ref.invalidate(schoolTeachersProvider(schoolId));
  });

  Future<String?> deleteClass(
    String schoolId, {
    required String classId,
  }) => _run(() => _repo.deleteSchoolClass(schoolId, classId), () {
    _ref.invalidate(schoolClassesProvider(schoolId));
    _ref.invalidate(schoolTeachersProvider(schoolId));
    _refreshSchools();
  });

  Future<String?> removeClassTeacher(
    String schoolId, {
    required String classId,
  }) => _run(() => _repo.removeClassTeacher(schoolId, classId), () {
    _ref.invalidate(schoolClassesProvider(schoolId));
    _ref.invalidate(schoolTeachersProvider(schoolId));
  });

  // ================================================================
  // SCHOOL ADMINS
  // ================================================================

  Future<String?> updateAdmin(
    String schoolId, {
    required String adminId,
    required String fullName,
    required String email,
    String? phoneNumber,
    String? newPassword,
  }) => _run(
    () => _repo.updateSchoolAdmin(
      schoolId,
      adminId,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      newPassword: newPassword,
    ),
    () => _ref.invalidate(schoolAdminAccountsProvider(schoolId)),
  );

  Future<String?> deleteAdmin(
    String schoolId, {
    required String adminId,
  }) => _run(() => _repo.deleteSchoolAdmin(schoolId, adminId), () {
    _ref.invalidate(schoolAdminAccountsProvider(schoolId));
    _refreshSchools(); // admin count
  });

  // ================================================================
  // SUBJECTS
  // ================================================================

  void _subjectsChanged(String schoolId) {
    _ref.invalidate(schoolSubjectsProvider(schoolId));
    _ref.invalidate(schoolClassesProvider(schoolId)); // subject counts
    _ref.invalidate(schoolTeachersProvider(schoolId)); // subjects taught
    _ref.invalidate(schoolFormOptionsProvider(schoolId)); // trade subjects
  }

  Future<String?> createSubject(
    String schoolId, {
    required String name,
    String? code,
    required int type,
    String? departmentId,
    String? tradeId,
  }) => _run(
    () => _repo.createSchoolSubject(
      schoolId,
      name: name,
      code: code,
      type: type,
      departmentId: departmentId,
      tradeId: tradeId,
    ),
    () {
      _subjectsChanged(schoolId);
      _refreshSchools();
    },
  );

  Future<String?> updateSubject(
    String schoolId, {
    required String subjectId,
    required String name,
    String? code,
    required int type,
    String? departmentId,
    String? tradeId,
  }) => _run(
    () => _repo.updateSchoolSubject(
      schoolId,
      subjectId,
      name: name,
      code: code,
      type: type,
      departmentId: departmentId,
      tradeId: tradeId,
    ),
    () => _subjectsChanged(schoolId),
  );

  Future<String?> deleteSubject(
    String schoolId, {
    required String subjectId,
  }) => _run(() => _repo.deleteSchoolSubject(schoolId, subjectId), () {
    _subjectsChanged(schoolId);
    _refreshSchools();
  });

  Future<String?> assignSubject(
    String schoolId, {
    required String subjectId,
    required List<String> classIds,
    String? teacherId,
  }) => _run(
    () => _repo.assignSchoolSubject(
      schoolId,
      subjectId,
      classIds: classIds,
      teacherId: teacherId,
    ),
    () => _subjectsChanged(schoolId),
  );

  Future<String?> removeSubjectFromClass(
    String schoolId, {
    required String subjectId,
    required String classId,
  }) => _run(
    () => _repo.removeSubjectFromClass(schoolId, subjectId, classId),
    () => _subjectsChanged(schoolId),
  );

  // Runs [call]; on success runs [after] and returns null, otherwise
  // returns the server's message.
  Future<String?> _run(
    Future<void> Function() call,
    void Function() after,
  ) async {
    try {
      await call();
    } catch (error) {
      return schoolPeopleError(error);
    }
    after();
    return null;
  }

  // Updates the counts on the dashboard / School Management page.
  void _refreshSchools() {
    _ref.read(superAdminProvider.notifier).getSchools();
  }
}

// ====================================================================
// FRIENDLY ERROR
// ====================================================================
// Turns a Dio error into the server's message (e.g. "A user with this
// email already exists.") instead of the long DioException text.

String schoolPeopleError(Object error) {
  try {
    final data = (error as dynamic).response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['Message'];
      if (message != null && '$message'.trim().isNotEmpty) return '$message';

      // ASP.NET validation errors: { errors: { Email: ["..."] } }
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return '${first.first}';
        return '$first';
      }
    }
    final status = (error as dynamic).response?.statusCode;
    if (status == 404) {
      return 'This is not available yet. Make sure the server has the '
          'latest super admin endpoints.';
    }
    if (status == 403) return "You don't have permission to do this.";
  } catch (_) {}

  final text = error.toString().replaceFirst('Exception: ', '').trim();
  if (text.isEmpty || text.contains('DioException')) {
    return 'Something went wrong. Check your connection and try again.';
  }
  return text;
}