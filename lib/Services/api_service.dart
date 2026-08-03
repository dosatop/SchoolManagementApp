import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:app/Dtos/auth_dtos/login_request.dart';
import 'package:app/Dtos/auth_dtos/login_response.dart';
import 'package:app/Dtos/auth_dtos/sign_up_request.dart';
import 'package:app/Dtos/user_dtos/user.dart';
import 'package:app/Errors/custom_exception_error.dart';
import 'package:app/Services/storage_service.dart';
import 'package:app/helpers/error/error_helper.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://usermanagementapi-k9f6.onrender.com/api';

  Future<List<dynamic>> fetchUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(response.body);
          return LoginResponse.fromJson(data);

        case 400:
          throw ValidationException(getMessage(response.body));

        case 401:
          throw UnauthorizedException(getMessage(response.body));

        case 403:
          throw ForbiddenException(getMessage(response.body));

        case 404:
          throw NotFoundException(getMessage(response.body));

        case 409:
          throw ConflictException(getMessage(response.body));

        case 500:
          throw const ServerException();

        default:
          throw const ApiException();
      }
    } on http.ClientException catch (e) {
      // Failed host lookup is reported as a ClientException by package:http.
      if (e.message.contains('Failed host lookup')) {
        throw const NetworkException.noInternet();
      }

      throw const NetworkException.generic();
    } on SocketException {
      throw const NetworkException.noInternet();
    } on TimeoutException {
      throw const NetworkException.timeout();
    }
  }

  Future<Map<String, dynamic>> signUp(SignUpRequest request) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/signUp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception(response.body);
  }

  Future<User> getUserDetails() async {
    final token = await StorageService().getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/user/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      return User.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to get user details: ${response.body}');
    }
  }
}
