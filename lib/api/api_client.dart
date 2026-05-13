import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage secureStorage;
  Function? onUnauthorized;

  ApiClient({required this.dio, required this.secureStorage}) {
    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 15);


    // Setup Interceptors (Matches React axios interceptor)
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        String? token = await secureStorage.read(key: 'jwt_token');
        if (token != null && token.isNotEmpty && token != 'null') {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // Handle 401 Unauthorized globally (except for set-pin / change-password loops)
        if (e.response?.statusCode == 401) {
          final path = e.requestOptions.path;
          // Don't trigger auto-logout on login screen or PIN/Password setup screens
          if (!path.contains('/auth/set-pin') && !path.contains('/auth/change-password') && !path.contains('/auth/login')) {
            print("401 Unauthorized detected. Triggering logout.");
            if (onUnauthorized != null) {
              onUnauthorized!();
            }
          }
        }
        return handler.next(e);
      },
    ));
  }

  // ==========================================
  // 1. AUTHENTICATION ENDPOINTS
  // ==========================================
  Future<Response> login(Map<String, dynamic> data) => dio.post('/auth/login', data: data);
  Future<Response> logout() => dio.post('/auth/logout');
  Future<Response> changePassword(Map<String, dynamic> data) => dio.post('/auth/change-password', data: data);
  Future<Response> setPin(Map<String, dynamic> data) => dio.post('/auth/set-pin', data: data);
  Future<Response> forgotPassword(Map<String, dynamic> data) => dio.post('/auth/forgot-password', data: data);
  Future<Response> resetPassword(Map<String, dynamic> data) => dio.post('/auth/reset-password', data: data);

  // ==========================================
  // 2. USER MANAGEMENT ENDPOINTS
  // ==========================================
  // Uses FormData because it includes the signature image upload (multipart/form-data)
  Future<Response> createUser(FormData data) => dio.post('/users', data: data);
  Future<Response> getUsers({String query = ''}) => dio.get('/users$query');
  Future<Response> updateUser(int id, Map<String, dynamic> data) => dio.patch('/users/$id', data: data);

  Future<Response> getDepartments() => dio.get('/users/departments');
  Future<Response> getDesignations() => dio.get('/users/designations');
  Future<Response> createDepartment(Map<String, dynamic> data) => dio.post('/users/departments', data: data);
  Future<Response> createDesignation(Map<String, dynamic> data) => dio.post('/users/designations', data: data);

  // ==========================================
  // 3. FILE MANAGEMENT ENDPOINTS
  // ==========================================
  Future<Response> createFile(Map<String, dynamic> data) => dio.post('/files', data: data);

  // Pagination matching React: drafts, inbox, outbox
  Future<Response> getDrafts({int limit = 10, String? cursor}) {
    Map<String, dynamic> queryParams = {'limit': limit};
    if (cursor != null) queryParams['cursor'] = cursor;
    return dio.get('/files/drafts', queryParameters: queryParams);
  }

  Future<Response> getInbox({int limit = 10, String? cursor}) {
    Map<String, dynamic> queryParams = {'limit': limit};
    if (cursor != null) queryParams['cursor'] = cursor;
    return dio.get('/files/inbox', queryParameters: queryParams);
  }

  Future<Response> getOutbox({int limit = 10, String? cursor}) {
    Map<String, dynamic> queryParams = {'limit': limit};
    if (cursor != null) queryParams['cursor'] = cursor;
    return dio.get('/files/outbox', queryParameters: queryParams);
  }

  Future<Response> searchFiles(Map<String, dynamic> queryParams) => dio.get('/files/search', queryParameters: queryParams);

  Future<Response> getFileHistory(int id, {Map<String, dynamic>? params}) => dio.get('/files/$id/history', queryParameters: params);

  // Downloading a file (Expects raw bytes back)
  Future<Response> downloadAttachment(int attachmentId) {
    return dio.get(
        '/files/attachment/$attachmentId/download',
        options: Options(responseType: ResponseType.bytes)
    );
  }

  // Uploading an attachment to a file (multipart/form-data)
  Future<Response> addAttachment(int id, FormData formData) => dio.post('/files/$id/attachment', data: formData);

  Future<Response> removeAttachment(int attachmentId) => dio.delete('/files/attachment/$attachmentId');

  // ==========================================
  // 4. WORKFLOW ENDPOINTS
  // ==========================================
  // Note: Data can be Map<String,dynamic> OR FormData (if it includes attachments)
  Future<Response> moveFile(int fileId, dynamic data) {
    return dio.post('/workflow/files/$fileId/move', data: data);
  }

  // ==========================================
  // 5. COMMON / SYSTEM ENDPOINTS
  // ==========================================
  Future<Response> getHealth() => dio.get('/health');
  Future<Response> getConstants() => dio.get('/constants');
}