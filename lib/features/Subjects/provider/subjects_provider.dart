import 'package:app/features/Subjects/models/create_subject_request.dart';
import 'package:app/features/Subjects/models/subject_model.dart';
import 'package:app/features/super_admin/provider/schools_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final subjectsProvider =
    AsyncNotifierProvider.family<SubjectsNotifier, List<SubjectModel>, String>(
      SubjectsNotifier.new,
    );

class SubjectsNotifier extends FamilyAsyncNotifier<List<SubjectModel>, String> {
  @override
  Future<List<SubjectModel>> build(String schoolId) async {
    final repository = ref.read(superAdminRepositoryProvider);

    return repository.getSubjects(schoolId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(superAdminRepositoryProvider);

      final subjects = await repository.getSubjects(arg);

      state = AsyncData(subjects);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<String?> createSubject(CreateSubjectRequest request) async {
    try {
      final repository = ref.read(superAdminRepositoryProvider);

      await repository.createSubject(arg, request);

      // Reload subjects after creation.
      final subjects = await repository.getSubjects(arg);

      state = AsyncData(subjects);

      return null;
    } catch (error) {
      return error.toString();
    }
  }
}
