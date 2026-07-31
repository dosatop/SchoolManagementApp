import 'dart:convert';
import 'package:app/Dtos/auth_dtos/login_request.dart';
import 'package:app/Dtos/auth_dtos/login_response.dart';
import 'package:app/Dtos/auth_dtos/sign_up_request.dart';
import 'package:app/Services/storage_service.dart';
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
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return LoginResponse.fromJson(data);
    } else {
      throw Exception(
        'Failed to login: ${response.statusCode}, error: ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> signUp(SignUpRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signUp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception(response.body);
  }

  Future<Map<String, dynamic>> getUserDetails() async {
    final token = await StorageService().getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/user/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user details: ${response.body}');
    }
  }
}
