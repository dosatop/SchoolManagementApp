// import 'package:app/features/admin/providers/admin_provider.dart';
// import 'package:app/features/students/models/create_student_request.dart';
// import 'package:app/features/students/models/student_model.dart';
// import 'package:app/features/super_admin/provider/schools_page.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// final studentsProvider =
//     AsyncNotifierProvider.family<StudentsNotifier, List<StudentModel>, String>(
//       StudentsNotifier.new,
//     );

// class StudentsNotifier extends FamilyAsyncNotifier<List<StudentModel>, String> {
//   @override
//   Future<List<StudentModel>> build(String schoolId) async {
//     final repository = ref.read(adminRepositoryProvider);

//     // return repository.getStudents();
//   }

//   Future<void> refresh() async {
//     state = const AsyncLoading();

//     try {
//       final repository = ref.read(adminRepositoryProvider);

//       final students = await repository.getStudents();

//       state = AsyncData(students);
//     } catch (error, stackTrace) {
//       state = AsyncError(error, stackTrace);
//     }
//   }

//   // ===============================================================
//   // CREATE STUDENT
//   // ===============================================================

//   Future<String?> createStudent(CreateStudentRequest request) async {
//     try {
//       final repository = ref.read(superAdminRepositoryProvider);

//       await repository.createStudent(arg, request);

//       // Refresh the list after successful creation.
//       final students = await repository.getStudents(arg);

//       state = AsyncData(students);

//       return null;
//     } catch (error) {
//       return error.toString();
//     }
//   }
// }
