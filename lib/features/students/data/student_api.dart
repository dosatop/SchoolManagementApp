import 'package:app/core/network/dio_client.dart';
import 'package:app/features/students/models/student_model.dart';

class StudentApi {
  final DioClient dioClient;

  StudentApi(this.dioClient);

  Future<StudentModel> getStudentProfile() async {
    final response = await dioClient.dio.get(
      '/student/profile',
    );

    return StudentModel.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }
}