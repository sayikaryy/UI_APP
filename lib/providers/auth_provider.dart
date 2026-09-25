import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty && _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isCustomer => _currentUser?.isCustomer ?? false;

  AuthProvider() {
    _apiClient.onUnauthorized = () {
      logout();
    };
  }

  Future<bool> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiClient.init();
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(ApiConstants.keyToken);
      final savedUserJson = prefs.getString(ApiConstants.keyUser);

      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        await _apiClient.setAuthToken(savedToken);

        if (savedUserJson != null) {
          _currentUser = UserModel.fromJson(jsonDecode(savedUserJson));
        }

        // Fetch fresh profile in the background
        try {
          final res = await _apiClient.get(ApiConstants.profile);
          if (res != null && res['data'] != null) {
            _currentUser = UserModel.fromJson(res['data']);
            await prefs.setString(ApiConstants.keyUser, jsonEncode(_currentUser!.toJson()));
          }
        } catch (_) {
          // If offline or fetch failed, fallback to cached user
        }

        _isLoading = false;
        notifyListeners();
        return _currentUser != null;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.post(ApiConstants.login, body: {
        'email': email.trim(),
        'password': password,
      });

      if (res != null && res['success'] == true) {
        _token = res['token'];
        _currentUser = UserModel.fromJson(res['user']);

        await _apiClient.setAuthToken(_token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ApiConstants.keyUser, jsonEncode(_currentUser!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res?['message'] ?? 'Login failed';
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? address,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.post(ApiConstants.register, body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'phone': phone,
        'address': address,
      });

      if (res != null && res['success'] == true) {
        _token = res['token'];
        _currentUser = UserModel.fromJson(res['user']);

        await _apiClient.setAuthToken(_token);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ApiConstants.keyUser, jsonEncode(_currentUser!.toJson()));

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res?['message'] ?? 'Registration failed';
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Registration failed. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> updateProfile({String? name, String? phone, String? address}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _apiClient.put(ApiConstants.profile, body: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
      });

      if (res != null && res['user'] != null) {
        _currentUser = UserModel.fromJson(res['user']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(ApiConstants.keyUser, jsonEncode(_currentUser!.toJson()));
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConstants.logout);
    } catch (_) {}

    _token = null;
    _currentUser = null;
    await _apiClient.setAuthToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiConstants.keyUser);
    notifyListeners();
  }
}
