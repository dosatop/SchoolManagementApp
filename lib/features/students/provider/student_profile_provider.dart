import 'package:app/core/network/dio_provider.dart';
import 'package:app/features/students/data/student_api.dart';
import 'package:app/features/students/data/student_repository.dart';
import 'package:app/features/students/models/student_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final studentApiProvider = Provider<StudentApi>((ref) {
  final dioClient = ref.read(dioClientProvider);

  return StudentApi(dioClient);
});

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  final api = ref.read(studentApiProvider);

  return StudentRepository(api: api);
});

final studentProfileProvider =
    AsyncNotifierProvider<StudentProfileNotifier, StudentModel?>(
  StudentProfileNotifier.new,
);

class StudentProfileNotifier extends AsyncNotifier<StudentModel?> {
  @override
  Future<StudentModel?> build() async {
    final repository = ref.read(studentRepositoryProvider);

    return repository.getStudentProfile();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(studentRepositoryProvider);

      final student = await repository.getStudentProfile();

      state = AsyncData(student);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}