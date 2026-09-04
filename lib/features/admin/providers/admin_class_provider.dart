import 'package:app/core/network/dio_provider.dart';
import 'package:app/features/admin/data/admin_api.dart';
import 'package:app/features/admin/data/admin_repository.dart';
import 'package:app/features/admin/models/classes/admin_assign_class_subject_request.dart';
import 'package:app/features/admin/models/classes/admin_class_model.dart';
import 'package:app/features/admin/models/classes/admin_get_class_subjects_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  final adminApi = AdminApi(dioClient);

  return AdminRepository(api: adminApi);
});

// FAMILY PROVIDER FOR ADMIN CLASS SUBJECT DETAILS
final adminClassSubjectDetailsProvider =
    FutureProvider.family<List<AdminGetClassSubjectModel>, String>((
      ref,
      classId,
    ) async {
      final adminRepository = ref.read(adminRepositoryProvider);
      return adminRepository.getAdminClassSubjects(classId);
    });

final adminClassProvider =
    AsyncNotifierProvider<AdminClassNotifier, List<AdminClassModel>>(
      AdminClassNotifier.new,
    );

class AdminClassNotifier extends AsyncNotifier<List<AdminClassModel>> {
  @override
  Future<List<AdminClassModel>> build() {
    return _loadClasses();
  }

  Future<List<AdminClassModel>> _loadClasses() async {
    final adminRepository = ref.read(adminRepositoryProvider);
    return adminRepository.getClasses();
  }

  Future<void> refreshClasses() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadClasses());
  }

  Future<void> assignSubjectToClass({
    required AdminAssignClassSubjectRequest data,
  }) async {
    final adminRepository = ref.read(adminRepositoryProvider);
    await adminRepository.assignSubjectToClass(data: data);
    await refreshClasses();
  }

  Future<void> unassignSubjectFromClass({
    required String classId,
    required String subjectId,
  }) async {
    final adminRepository = ref.read(adminRepositoryProvider);
    await adminRepository.unassignSubjectFromClass(
      classId: classId,
      subjectId: subjectId,
    );
    await refreshClasses();
  }

  Future<AdminClassModel> assignClassTeacher({
    required String classId,
    required String teacherId,
  }) async {
    final adminRepository = ref.read(adminRepositoryProvider);
    final classModel = await adminRepository.assignClassTeacher(
      classId: classId,
      teacherId: teacherId,
    );
    await refreshClasses();
    return classModel;
  }
}
