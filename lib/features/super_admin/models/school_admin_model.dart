class SchoolAdminModel {
  final String id;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String role;

  SchoolAdminModel({
    required this.id,
    required this.fullName,
    this.email,
    this.phoneNumber,
    required this.role,
  });

  factory SchoolAdminModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SchoolAdminModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      role: json['role'] as String,
    );
  }
}