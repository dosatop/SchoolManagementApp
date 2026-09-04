import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/features/admin/data/admin_api.dart';
import 'package:app/features/admin/data/admin_repository.dart';
import 'package:app/features/admin/models/students/admin_create_student_model.dart';
import 'package:app/features/admin/models/students/admin_edit_student_model.dart';
import 'package:app/features/admin/models/students/admin_student_detail_model.dart';
import 'package:app/features/admin/models/students/admin_student_model.dart';

import 'package:app/core/network/dio_provider.dart';

// ================================================================
// ADMIN REPOSITORY
// ================================================================

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final dioClient = ref.read(dioClientProvider);
  final adminApi = AdminApi(dioClient);
  return AdminRepository(
    api: adminApi,
  );
});


// ================================================================
// STUDENT DETAILS PROVIDER
// ================================================================

final adminStudentDetailsProvider =
    FutureProvider.family<AdminStudentDetailModel, String>(
  (ref, studentId) async {
    final repository = ref.read(adminRepositoryProvider);

    return repository.getStudentDetails(
      studentId: studentId,
    );
  },
);


// ================================================================
// STUDENT PROVIDER
// ================================================================

final adminStudentProvider =
    AsyncNotifierProvider<AdminStudentNotifier, List<AdminStudentModel>>(
  AdminStudentNotifier.new,
);


// ================================================================
// STUDENT NOTIFIER
// ================================================================

class AdminStudentNotifier
    extends AsyncNotifier<List<AdminStudentModel>> {

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Future<List<AdminStudentModel>> build() async {
    return _loadStudents();
  }


  // ================================================================
  // LOAD STUDENTS
  // ================================================================

  Future<List<AdminStudentModel>> _loadStudents() async {
    final repository = ref.read(adminRepositoryProvider);

    return repository.getStudents();
  }


  // ================================================================
  // REFRESH
  // ================================================================

  Future<void> refresh() async {
    state = const AsyncLoading();

    try {
      final students = await _loadStudents();

      state = AsyncData(students);
    } catch (error, stackTrace) {
      state = AsyncError(
        error,
        stackTrace,
      );
    }
  }


  // ================================================================
  // GET STUDENTS
  // ================================================================

  List<AdminStudentModel> get students {
    return state.value ?? [];
  }


  // ================================================================
  // GET STUDENTS FOR SCHOOL
  // ================================================================

  List<AdminStudentModel> getStudentsForSchool(
    String schoolId,
  ) {
    return students
        .where(
          (student) => student.schoolId == schoolId,
        )
        .toList();
  }


  // ================================================================
  // CREATE STUDENT
  // ================================================================

  Future<AdminStudentModel?> createStudent({
    required String schoolId,
    required AdminCreateStudentModel data,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      final student = await repository.createStudent(
        schoolId: schoolId,
        data: data,
      );

      final currentStudents = state.value ?? [];

      state = AsyncData([
        student,
        ...currentStudents,
      ]);

      return student;
    } catch (error, stackTrace) {
      state = AsyncError(
        error,
        stackTrace,
      );

      return null;
    }
  }


  // ================================================================
  // UPDATE STUDENT
  // ================================================================

  Future<AdminStudentModel?> updateStudent({
    required String studentId,
    required AdminEditStudentModel data,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      final updatedStudent =
          await repository.updateStudent(
        studentId: studentId,
        data: data,
      );

      final currentStudents = state.value ?? [];

      final updatedStudents =
          currentStudents.map((student) {
        if (student.studentId == studentId) {
          return updatedStudent;
        }

        return student;
      }).toList();

      state = AsyncData(updatedStudents);

      ref.invalidate(
        adminStudentDetailsProvider(studentId),
      );

      return updatedStudent;
    } catch (error, stackTrace) {
      state = AsyncError(
        error,
        stackTrace,
      );

      return null;
    }
  }


  // ================================================================
  // DELETE STUDENT
  // ================================================================

  Future<bool> deleteStudent({
    required String studentId,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      await repository.deleteStudent(
        studentId: studentId,
      );

      final currentStudents = state.value ?? [];

      final updatedStudents =
          currentStudents
              .where(
                (student) =>
                    student.studentId != studentId,
              )
              .toList();

      state = AsyncData(updatedStudents);

      ref.invalidate(
        adminStudentDetailsProvider(studentId),
      );

      return true;
    } catch (error, stackTrace) {
      state = AsyncError(
        error,
        stackTrace,
      );

      return false;
    }
  }


  // ================================================================
  // GET STUDENT BY ID
  // ================================================================

  Future<AdminStudentDetailModel?> getStudentById({
    required String studentId,
  }) async {
    try {
      final repository = ref.read(adminRepositoryProvider);

      return await repository.getStudentDetails(
        studentId: studentId,
      );
    } catch (error, stackTrace) {
      state = AsyncError(
        error,
        stackTrace,
      );

      return null;
    }
  }
}
