class AdminCreateParentRequestModel {
  final String fullName;
  final String phoneNumber;
  final String email;
  final String password;

  const AdminCreateParentRequestModel({
    required this.fullName,
    required this.phoneNumber,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'password': password,
    };
  }
}
