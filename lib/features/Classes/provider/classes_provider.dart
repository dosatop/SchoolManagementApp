import 'package:app/features/Classes/models/class_model.dart';
import 'package:app/features/Classes/models/create_class_request.dart';
import 'package:app/features/super_admin/provider/schools_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final classesProvider =
    AsyncNotifierProvider.family<ClassesNotifier, List<ClassModel>, String>(
      ClassesNotifier.new,
    );

class ClassesNotifier extends FamilyAsyncNotifier<List<ClassModel>, String> {
  @override
  Future<List<ClassModel>> build(String schoolId) async {
    final repository = ref.read(superAdminRepositoryProvider);

    return repository.getClasses(schoolId);
  }

  Future<void> refreshClasses() async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(superAdminRepositoryProvider);

      final classes = await repository.getClasses(arg);

      state = AsyncData(classes);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  // ============================================================
  // CREATE CLASS
  // ============================================================

  Future<String?> createClass(CreateClassRequest request) async {
    try {
      final repository = ref.read(superAdminRepositoryProvider);

      await repository.createClass(arg, request);

      // Refresh the list after successful creation.
      await refreshClasses();

      return null;
    } catch (error) {
      return error.toString();
    }
  }
}
