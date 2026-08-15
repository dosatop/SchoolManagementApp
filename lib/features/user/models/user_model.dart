class UserModel {
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String? schoolId;
  final String? schoolName;
  final String? role;

  UserModel({
    required this.phoneNumber,
    required this.email,
    required this.fullName,
    this.schoolId,
    this.role, this.schoolName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      phoneNumber: json['phoneNumber'] as String?,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      schoolId: json['schoolId'] as String?,
      schoolName: json['schoolName'] as String?,
      role: json['role'] as String?,
    );
  }
}
