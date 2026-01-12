import 'package:dio/dio.dart';
import 'package:frontend1/core/utils/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    print('🔐 AuthInterceptor - Request to: ${options.path}');
    
    // Get token from secure storage
    final token = await SecureStorage.getToken();
    
    // Add authorization header if token exists
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      print('✅ Added Authorization header');
      print('🔑 Token (first 20 chars): ${token.substring(0, min(20, token.length))}...');
    } else {
      print('⚠️ No token available for request');
    }
    
    // Add other common headers
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';
    
    print('📋 Final headers: ${options.headers}');
    
    return handler.next(options);
  }
  
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    print('❌ AuthInterceptor - Error: ${err.message}');
    print('❌ Status code: ${err.response?.statusCode}');
    
    // Handle 401 Unauthorized errors
    if (err.response?.statusCode == 401) {
      print('🔐 Token expired or invalid, clearing storage...');
      // Clear stored data
      await SecureStorage.clearAll();
      
      // You might want to add navigation logic here using a global key
      // For now, just print
      print('🚪 User logged out due to expired token');
    }
    
    return handler.next(err);
  }
  
  int min(int a, int b) => a < b ? a : b;
}