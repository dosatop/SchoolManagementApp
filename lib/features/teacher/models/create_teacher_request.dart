class CreateTeacherRequest {
  final String fullName;
  final String email;
  final String employeeNumber;
  final String password;

  CreateTeacherRequest({
    required this.fullName,
    required this.email,
    required this.employeeNumber,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'employeeNumber': employeeNumber,
      'password': password,
    };
  }
}