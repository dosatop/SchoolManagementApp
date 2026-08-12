class SignUpRequest {
  final String email;
  final String password;
  final String fullName;
  final String phoneNumber;

  SignUpRequest({
    required this.email,
    required this.password, required this.fullName, required this.phoneNumber,
   
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
    };
  }
}
