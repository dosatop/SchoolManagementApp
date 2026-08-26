class AdminTeacherClassModel {
  final String teacherId;
  final String classId;
  final String className;

  const AdminTeacherClassModel({
    required this.teacherId,
    required this.classId, required this.className,
  });

  factory AdminTeacherClassModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminTeacherClassModel(
      teacherId: json['teacherId']?.toString() ?? '',
      classId: json['classId']?.toString() ?? '',
      className: json['className']?.toString() ?? '',
    );
  }
}