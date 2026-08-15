class AdminTeacherClassModel {
  final String teacherId;
  final String classId;

  const AdminTeacherClassModel({
    required this.teacherId,
    required this.classId,
  });

  factory AdminTeacherClassModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminTeacherClassModel(
      teacherId: json['teacherId']?.toString() ?? '',
      classId: json['classId']?.toString() ?? '',
    );
  }
}