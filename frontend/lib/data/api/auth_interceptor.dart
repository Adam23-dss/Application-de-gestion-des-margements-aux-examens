import 'package:dio/dio.dart';
import 'package:frontend1/core/utils/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage = SecureStorage.instance;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    print('🔐 AuthInterceptor - Request to: ${options.uri}');
    
    try {
      // Récupérer le token depuis le stockage
      final token = await _storage.read(key: 'access_token');
      
      if (token != null && token.isNotEmpty) {
        print('✅ Adding Authorization header');
        print('🔑 Token (first 20 chars): ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
        
        options.headers['Authorization'] = 'Bearer $token';
      } else {
        print('⚠️ No token found in storage');
      }
      
      // Ajouter les headers par défaut
      options.headers['Content-Type'] = 'application/json';
      options.headers['Accept'] = 'application/json';
      
      print('📋 Final headers: ${options.headers}');
      
    } catch (e) {
      print('❌ Error in AuthInterceptor: $e');
    }
    
    return super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('❌ AuthInterceptor - Error: ${err.response?.statusCode}');
    
    if (err.response?.statusCode == 401) {
      print('🔒 Unauthorized - Token may be expired');
      // Tu pourrais ajouter ici une logique pour rafraîchir le token
    }
    
    return super.onError(err, handler);
  }
}