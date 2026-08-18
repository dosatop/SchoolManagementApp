class AdminTeacherSubjectModel {
  final String subjectId;
  final String name;
  final String code;
  final String classId;
  final String className;

  const AdminTeacherSubjectModel({
    required this.subjectId,
    required this.name,
    required this.code,
    required this.classId,
    required this.className,
  });

  factory AdminTeacherSubjectModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminTeacherSubjectModel(
      subjectId: json['subjectId']?.toString() ?? '',
      name: json['subjectName']?.toString() ??
          json['name']?.toString() ??
          '',
      code: json['code']?.toString() ?? '',
      classId: json['classId']?.toString() ?? '',
      className: json['className']?.toString() ?? '',
    );
  }

  AdminTeacherSubjectModel copyWith({
    String? subjectId,
    String? name,
    String? code,
    String? classId,
    String? className,
  }) {
    return AdminTeacherSubjectModel(
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      code: code ?? this.code,
      classId: classId ?? this.classId,
      className: className ?? this.className,
    );
  }
}