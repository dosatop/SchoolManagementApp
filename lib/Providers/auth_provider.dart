import 'package:app/Dtos/auth_dtos/login_request.dart';
import 'package:app/Dtos/auth_dtos/sign_up_request.dart';
import 'package:app/Errors/custom_exception_error.dart';
import 'package:app/Services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:app/Services/api_service.dart';
import 'package:http/http.dart' as http show ClientException;

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<bool> login(LoginRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.login(request);

      await _storage.saveToken(response.accessToken);

      return true;
    } on ApiException catch (e) {
      _error = e.message;
      return false;
    } catch (e) {
      _error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(SignUpRequest request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.signUp(request);

      _isLoading = false;
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();

      _isLoading = false;
      notifyListeners();

      return false;
    }
  }
}
