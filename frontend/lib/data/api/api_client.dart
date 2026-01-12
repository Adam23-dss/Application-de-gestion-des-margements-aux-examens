import 'package:dio/dio.dart';
import 'package:frontend1/core/constants/api_endpoints.dart';
import 'auth_interceptor.dart';

class ApiClient {
  // Singleton instance
  static final ApiClient _singleton = ApiClient._internal();
  
  factory ApiClient() {
    return _singleton;
  }
  
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ),
    );
    
    // Add interceptor for auth
    _dio.interceptors.add(AuthInterceptor());
  }
  
  late final Dio _dio;
  
  // Getter for Dio instance
  Dio get dio => _dio;
  
  // Static getter for convenience
  static Dio get instance => _singleton.dio;
}