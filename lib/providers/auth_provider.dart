// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;

  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  AuthProvider({required this.apiClient, required this.secureStorage}) {
    _checkAuthStatus();
  }

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;

  // Run on app startup to check if user is already logged in
  Future<void> _checkAuthStatus() async {
    String? token = await secureStorage.read(key: 'jwt_token');

    if (token != null) {
      try {
        // Call your backend route
        final response = await apiClient.dio.get('/auth/me');

        if (response.statusCode == 200) {
          // 🟢 UPDATE: Since your backend sends the DTO directly inside 'data'
          // We assign response.data['data'] directly to _user
          _user = response.data['data']['user'] ?? response.data['data'];

          _isAuthenticated = true;
          print("User restored successfully: ${_user?['fullName']}");
        }
      } on DioException catch (e) {
        // If the token is expired or invalid (e.g., 401 Unauthorized)
        print("Token invalid or expired: ${e.message}. Forcing logout.");
        await logout();
      } catch (e) {
        print("Unknown error during auth check: $e");
        await logout();
      }
    }

    _isLoading = false;
    notifyListeners();
  }
  void updatePinStatus(bool status) {
    if (_user != null) {
      // Update the user's map in memory
      _user!['isPinSet'] = status;

      // Notify all listening widgets (like the dashboard or profile screen) to rebuild
      notifyListeners();

    }
  }

  // Login function matching your React onSubmit
// Update your login function in auth_provider.dart
  Future<bool> login(String phoneNumber, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.dio.post('/auth/login', data: {
        'phoneNumber': phoneNumber,
        'password': password,
      });

      if (response.statusCode == 200) {
        // Updated to match the new backend JSON structure
        final token = response.data['token'];
        await secureStorage.write(key: 'jwt_token', value: token);

        _user = response.data['data']['user'];
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      // 🟢 Safely print the exact error coming from your backend (like Joi validation errors)
      final errorMessage = e.response?.data['message'] ?? e.response?.data ?? e.message;
      print('Login Error from Backend: $errorMessage');
    } catch (e) {
      print('Unexpected App Error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Logout function
  // --- Add this inside AuthProvider ---
  Future<void> logout() async {
    try {
      // Hit the backend to blacklist the token in Redis
      await apiClient.logout();
    } catch (e) {
      print("Backend logout failed (token might already be expired), clearing local data anyway.");
    }

    // Wipe local storage
    await secureStorage.delete(key: 'jwt_token');
    _isAuthenticated = false;
    _user = null;

    // Notify the app to kick the user back to the Login screen
    notifyListeners();
  }
}