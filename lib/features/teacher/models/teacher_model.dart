class TeacherModel {
  final String id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String schoolId;
  final String role;

  const TeacherModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.schoolId,
    required this.role,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      schoolId: json['schoolId']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Teacher',
    );
  }
}