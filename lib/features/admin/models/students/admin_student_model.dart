import 'package:app/features/admin/models/students/admin_student_parent_model.dart';

class AdminStudentModel {
  final String studentId;
  final String studentNumber;
  final String schoolId;
  final String schoolName;
  final String studentName;
  final String email;
  final String? phoneNumber;
  final String classId;
  final String className;
  final List<AdminStudentParentModel> parents;

  const AdminStudentModel({
    required this.studentId,
    required this.studentNumber,
    required this.schoolId,
    required this.schoolName,
    required this.studentName,
    required this.email,
    this.phoneNumber,
    required this.classId,
    required this.className,
    required this.parents,
  });

  factory AdminStudentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminStudentModel(
      studentId: json['studentId']?.toString() ?? '',
      studentNumber: json['studentNumber']?.toString() ?? '',
      schoolId: json['schoolId']?.toString() ?? '',
      schoolName: json['schoolName']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      classId: json['classId']?.toString() ?? '',
      className: json['className']?.toString() ?? '',
      parents: (json['parents'] as List<dynamic>? ?? [])
          .map(
            (item) => AdminStudentParentModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}