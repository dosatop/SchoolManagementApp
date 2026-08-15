import 'package:app/features/students/data/student_api.dart';
import 'package:app/features/students/models/student_model.dart';

class StudentRepository {
  final StudentApi api;

  StudentRepository({required this.api});

  Future<StudentModel> getStudentProfile() {
    return api.getStudentProfile();
  }
}