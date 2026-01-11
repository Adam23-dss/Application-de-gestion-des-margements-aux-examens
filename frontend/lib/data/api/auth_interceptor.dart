import 'package:dio/dio.dart';
import 'package:frontend1/core/utils/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Get token from secure storage
    final token = await SecureStorage.getToken();
    
    // Add authorization header if token exists
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    // Add other common headers
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';
    
    return handler.next(options);
  }
  
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle 401 Unauthorized errors
    if (err.response?.statusCode == 401) {
      // Clear stored data and redirect to login
      await SecureStorage.clearAll();
      // You might want to add navigation logic here using a global key
    }
    
    return handler.next(err);
  }
}