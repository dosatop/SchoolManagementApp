class SignUpRequest {
  final String email;
  final String password;
  final String fullName;
  final String mobileNumber;

  SignUpRequest({
    required this.email,
    required this.password, required this.fullName, required this.mobileNumber,
   
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'fullName': fullName,
      'mobileNumber': mobileNumber,
    };
  }
}
