class LoginInfoDto {
  final String email;
  final String password;
  final bool rememberMe;

  LoginInfoDto({
    required this.email,
    required this.rememberMe,
    required this.password,
  });

  factory LoginInfoDto.fromJson(Map<String, dynamic> json) {
    return LoginInfoDto(
      email: json['email'] as String,
      password: json['password'] as String,
      rememberMe: json['rememberMe'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password, 'rememberMe': rememberMe};
  }
}
