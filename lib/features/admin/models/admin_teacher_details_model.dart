import 'package:app/features/admin/models/admin_teacher_class_model.dart';
import 'package:app/features/admin/models/admin_teacher_subject_model.dart';

class AdminTeacherModel {
  final String teacherId;
  final String userId;
  final String schoolId;
  final String employeeNumber;
  final String teacherName;
  final String fullName;
  final String email;
  final String? phoneNumber;

  // Whether this teacher is a class teacher
  final bool isClassTeacher;

  // The class this teacher is the class teacher for
  final AdminTeacherClassModel? classTeacher;

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
    required this.fullName,
    required this.isClassTeacher,
    required this.classTeacher,
  });

  factory AdminTeacherModel.fromJson(Map<String, dynamic> json) {
    final classTeacherJson = json['classTeacher'];

    return AdminTeacherModel(
      teacherId: json['teacherId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      schoolId: json['schoolId']?.toString() ?? '',
      employeeNumber: json['employeeNumber']?.toString() ?? '',

      // API returns fullName, not teacherName
      teacherName: json['fullName']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',

      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),

      // API returns this
      isClassTeacher: json['isClassTeacher'] == true,

      // API returns one classTeacher object
      classTeacher: classTeacherJson is Map
          ? AdminTeacherClassModel.fromJson(
              Map<String, dynamic>.from(classTeacherJson),
            )
          : null,

      // Keep this for compatibility with other parts of your app.
      // The details endpoint doesn't return "classes", so use
      // classTeacher as the single class where appropriate.
      classes: classTeacherJson is Map
          ? [
              AdminTeacherClassModel.fromJson(
                Map<String, dynamic>.from(classTeacherJson),
              ),
            ]
          : [],

      subjects: (json['subjects'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map(
            (item) => AdminTeacherSubjectModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}