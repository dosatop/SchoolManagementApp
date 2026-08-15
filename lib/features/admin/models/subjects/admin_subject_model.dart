class AdminSubjectModel {
  final String subjectId;
  final String schoolId;
  final String subjectName;
  final String code;
  final List<AdminSubjectTeacherModel> teacherSubjects;

  const AdminSubjectModel({
    required this.subjectId,
    required this.schoolId,
    required this.subjectName,
    required this.code,
    required this.teacherSubjects,
  });

  factory AdminSubjectModel.fromJson(Map<String, dynamic> json) {
    return AdminSubjectModel(
      subjectId: json['subjectId'] ?? '',
      schoolId: json['schoolId'] ?? '',
      subjectName: json['subjectName'] ?? '',
      code: json['code'] ?? '',
      teacherSubjects: (json['teacherSubjects'] as List? ?? [])
          .map(
            (item) => AdminSubjectTeacherModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  AdminSubjectModel copyWith({
    String? subjectId,
    String? schoolId,
    String? subjectName,
    String? code,
    List<AdminSubjectTeacherModel>? teacherSubjects,
  }) {
    return AdminSubjectModel(
      subjectId: subjectId ?? this.subjectId,
      schoolId: schoolId ?? this.schoolId,
      subjectName: subjectName ?? this.subjectName,
      code: code ?? this.code,
      teacherSubjects: teacherSubjects ?? this.teacherSubjects,
    );
  }
}

class AdminSubjectTeacherModel {
  final String teacherId;
  final String teacherName;
  final String? email;
  final String? phoneNumber;

  const AdminSubjectTeacherModel({
    required this.teacherId,
    required this.teacherName,
    this.email,
    this.phoneNumber,
  });

  factory AdminSubjectTeacherModel.fromJson(Map<String, dynamic> json) {
    return AdminSubjectTeacherModel(
      teacherId: json['teacherId'] ?? '',
      teacherName: json['teacherName'] ?? '',
      email: json['email'],
      phoneNumber: json['phoneNumber'],
    );
  }
}