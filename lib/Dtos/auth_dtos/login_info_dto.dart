class LoginInfoDto {
  final String email;
  final bool rememberMe;

  LoginInfoDto({required this.email, required this.rememberMe});

  factory LoginInfoDto.fromJson(Map<String, dynamic> json) {
    return LoginInfoDto(
      email: json['email'] as String,
      rememberMe: json['rememberMe'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'rememberMe': rememberMe,
    };
  }
}