import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend1/core/constants/app_constants.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.authTokenKey);
    
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    options.headers['Content-Type'] = 'application/json';
    options.headers['Accept'] = 'application/json';
    
    return handler.next(options);
  }
}