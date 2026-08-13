import 'package:app/core/Dtos/auth_dtos/login_request.dart';
import 'package:app/core/Dtos/auth_dtos/login_response.dart';
import 'package:app/core/Errors/app_exception.dart';
import 'package:app/core/Errors/custom_exception_error.dart';
import 'package:app/core/network/dio_client.dart';
import 'package:app/features/auth/models/signup_request.dart';
import 'package:dio/dio.dart';

class AuthApi {
  final DioClient dioClient;

  AuthApi(this.dioClient);

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await dioClient.dio.post(
        '/auth/login',
        data: request.toJson(),
      );

      return LoginResponse.fromJson(response.data);
    } on DioException catch (error) {
      throw AppException(ApiErrorHandler.getCode(error));
    }
  }

  Future<String> signup(SignupRequest request) async {
    try {
      final response = await dioClient.dio.post(
        '/auth/signup',
        data: request.toJson(),
      );

      return response.data;
    } on DioException catch (error) {
      throw AppException(ApiErrorHandler.getCode(error));
    }
  }

  Future<void> logout() async {
    try {
      await dioClient.dio.post('/auth/logout');
    } on DioException catch (error) {
      throw AppException(ApiErrorHandler.getCode(error));
    }
  }
}
