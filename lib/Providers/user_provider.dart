import 'package:app/Dtos/user_dtos/user.dart';
import 'package:app/Services/api_service.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  final ApiService api;

  UserProvider(this.api);

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUserDetails() async {
    try {
      _isLoading = true;
      notifyListeners();

      _user = await api.getUserDetails();

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}