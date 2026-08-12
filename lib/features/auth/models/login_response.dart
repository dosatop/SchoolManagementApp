import 'package:app/features/user/models/user_model.dart';

class LogInResponse {
  final String token;
  final String tokenType;
  final int expiresIn;
  final UserModel user;

  LogInResponse({
    required this.token,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory LogInResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];

    return LogInResponse(
      token: data['token'],
      tokenType: data['tokenType'],
      expiresIn: data['expiresIn'],
      user: UserModel.fromJson(data['user']),
    );
  }

  void operator [](String other) {}
}

