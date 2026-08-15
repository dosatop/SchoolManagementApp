import 'package:app/features/super_admin/provider/schools_page.dart';
import 'package:app/features/teacher/models/create_teacher_request.dart';
import 'package:app/features/teacher/models/teacher_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final teachersProvider =
    AsyncNotifierProvider.family<TeachersNotifier, List<TeacherModel>, String>(
      TeachersNotifier.new,
    );

class TeachersNotifier extends FamilyAsyncNotifier<List<TeacherModel>, String> {
  @override
  Future<List<TeacherModel>> build(String schoolId) async {
    final repository = ref.read(superAdminRepositoryProvider);

    return repository.getTeachers(schoolId);
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> getTeachers() async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(superAdminRepositoryProvider);

      final teachers = await repository.getTeachers(arg);

      state = AsyncData(teachers);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<String?> createTeacher(CreateTeacherRequest request) async {
    try {
      final repository = ref.read(superAdminRepositoryProvider);

      await repository.createTeacher(arg, request);

      // Refresh the teachers list after creation.
      await getTeachers();

      return null;
    } catch (error) {
      return error.toString();
    }
  }
}
