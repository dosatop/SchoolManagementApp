class CreateSchoolAdminRequest {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;

  const CreateSchoolAdminRequest({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'password': password,
    };
  }
}