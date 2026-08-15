import 'package:app/core/Dtos/auth_dtos/token_response.dart';
import 'package:app/features/user/models/user_model.dart';

class LoginResponse {
  final String id;
  final String fullName;
  final String? phoneNumber;
  final String email;
  final String role;
  final String? schoolId;
  final String? schoolName;
  final TokenResponse tokenResponse;
  final UserModel user;

  LoginResponse({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    required this.email,
    required this.role,
    this.schoolId,
    this.schoolName,
    required this.tokenResponse,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      schoolId: json['schoolId'] as String?,
      schoolName: json['schoolName'] as String?,

      tokenResponse: TokenResponse.fromJson(
        json['tokenResponse'] as Map<String, dynamic>,
      ),

      // IMPORTANT:
      // The API does NOT return json['user'].
      // The user data is at the top level.
      user: UserModel.fromJson(json),
    );
  }
}
