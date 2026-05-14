// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../core/navigation/navigator_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;

  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  bool _isInitialLoading = true;
  bool _isAuthLoading = false;
  String? _authError;

  AuthProvider({required this.apiClient, required this.secureStorage}) {
    // 🟢 Setup global 401 Unauthorized handler
    apiClient.onUnauthorized = logout;
    _checkAuthStatus();
  }


  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isInitialLoading; // Still used by main.dart for splash
  bool get isAuthLoading => _isAuthLoading; // New for login button
  String? get authError => _authError;

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

    _isInitialLoading = false;
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
    _isAuthLoading = true;
    _authError = null; // Clear previous errors
    notifyListeners();

    try {
      final response = await apiClient.dio.post('/auth/login', data: {
        'phoneNumber': phoneNumber,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'];
        await secureStorage.write(key: 'jwt_token', value: token);

        _user = response.data['data']['user'];
        _isAuthenticated = true;
        _isAuthLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        _authError = "Server is taking too long to respond. Please check your connection.";
      } else if (e.type == DioExceptionType.connectionError) {
        _authError = "Cannot connect to server. Please check if the server is running.";
      } else {
        _authError = e.response?.data['message'] ?? e.response?.data?.toString() ?? e.message ?? "Authentication failed";
      }
      print('Login Error: $_authError');
    } catch (e) {
      _authError = "An unexpected error occurred. Please try again.";
      print('Unexpected App Error: $e');
    }

    _isAuthLoading = false;
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

    // 🟢 Force navigation to login and clear any existing screens on the stack
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushNamedAndRemoveUntil('/login', (route) => false);
    }

    // Notify the app to kick the user back to the Login screen
    notifyListeners();
  }

  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await apiClient.changePassword({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Password changed successfully',
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to change password',
      };
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? e.message;
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String phoneNumber) async {
    _isAuthLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final response = await apiClient.forgotPassword({
        'phoneNumber': phoneNumber,
      });

      _isAuthLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'OTP sent successfully',
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to request OTP',
      };
    } on DioException catch (e) {
      _isAuthLoading = false;
      notifyListeners();
      final errorMessage = e.response?.data['message'] ?? e.message;
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      _isAuthLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  Future<Map<String, dynamic>> resetPassword(String phoneNumber, String otp, String newPassword) async {
    _isAuthLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final response = await apiClient.resetPassword({
        'phoneNumber': phoneNumber,
        'otp': otp,
        'newPassword': newPassword,
      });

      _isAuthLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Password reset successfully',
        };
      }
      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed to reset password',
      };
    } on DioException catch (e) {
      _isAuthLoading = false;
      notifyListeners();
      final errorMessage = e.response?.data['message'] ?? e.message;
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      _isAuthLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }
}