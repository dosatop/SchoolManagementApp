class AdminTeacherSubjectModel {
  final String subjectId;
  final String name;
  final String code;

  const AdminTeacherSubjectModel({
    required this.subjectId,
    required this.name,
    required this.code,
  });

  factory AdminTeacherSubjectModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminTeacherSubjectModel(
      subjectId: json['subjectId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }
}