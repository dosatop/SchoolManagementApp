import 'package:app/features/admin/models/admin_teacher_class_model.dart';
import 'package:app/features/admin/models/admin_teacher_subject_model.dart';

class AdminTeacherModel {
  final String teacherId;
  final String userId;
  final String schoolId;
  final String employeeNumber;
  final String teacherName;
  final String email;
  final String? phoneNumber;
  final List<AdminTeacherClassModel> classes;
  final List<AdminTeacherSubjectModel> subjects;

  const AdminTeacherModel({
    required this.teacherId,
    required this.userId,
    required this.schoolId,
    required this.employeeNumber,
    required this.teacherName,
    required this.email,
    this.phoneNumber,
    required this.classes,
    required this.subjects,
  });

  factory AdminTeacherModel.fromJson(Map<String, dynamic> json) {
    return AdminTeacherModel(
      teacherId: json['teacherId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      schoolId: json['schoolId']?.toString() ?? '',
      employeeNumber: json['employeeNumber']?.toString() ?? '',
      teacherName: json['teacherName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),

      classes: (json['classes'] as List<dynamic>? ?? [])
          .map(
            (item) => AdminTeacherClassModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),

      subjects: (json['subjects'] as List<dynamic>? ?? [])
          .map(
            (item) => AdminTeacherSubjectModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}
