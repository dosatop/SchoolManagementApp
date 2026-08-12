import 'package:app/core/Dtos/auth_dtos/token_response.dart';

class LoginResponse {
  final String id;
  final String fullName;
  final String? phoneNumber;
  final String email;
  final TokenResponse tokenResponse;

  LoginResponse({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    required this.email,
    required this.tokenResponse,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String,
      tokenResponse: TokenResponse.fromJson(
        json['tokenResponse'] as Map<String, dynamic>,
      ),
    );
  }
}
