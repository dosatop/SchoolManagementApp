import 'package:flutter/foundation.dart';

class AdminTeacherSubjectModel {
  final String assignmentId;
  final String teacherId;
  final String teacherName;
  final String subjectId;
  final String name;
  final String code;
  final String classId;
  final String className;

  const AdminTeacherSubjectModel({
    required this.assignmentId,
    required this.teacherId,
    required this.teacherName,
    required this.subjectId,
    required this.name,
    required this.code,
    required this.classId,
    required this.className,
  });

  factory AdminTeacherSubjectModel.fromJson(Map<String, dynamic> json) {
    debugPrint('TEACHER SUBJECT JSON: $json');
    return AdminTeacherSubjectModel(
      assignmentId: json['assignmentId']?.toString() ?? '',

      teacherId: json['teacherId']?.toString() ?? '',

      teacherName: json['teacherName']?.toString() ?? '',

      subjectId: json['subjectId']?.toString() ?? '',

      name: json['subjectName']?.toString() ?? '',

      // If the GET response provides code.
      code: json['subjectCode']?.toString() ?? json['code']?.toString() ?? '',

      classId: json['classId']?.toString() ?? '',

      className: json['className']?.toString() ?? '',
    );
  }
}
