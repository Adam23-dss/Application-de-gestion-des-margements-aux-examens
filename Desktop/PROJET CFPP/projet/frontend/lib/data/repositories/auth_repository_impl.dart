import 'package:dio/dio.dart';
import '../api/dio_client.dart';
import '../api/endpoints.dart';
import '../../services/storage_service.dart';

class AuthRepositoryImpl {
  final DioClient client;
  final StorageService storage;

  AuthRepositoryImpl({
    required this.client,
    required this.storage,
  });

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final Response<dynamic> res = await client.dio.post(
      Endpoints.login,
      data: {
        "email": email,
        "password": password,
      },
    );

    final Map<String, dynamic> data =
        res.data as Map<String, dynamic>;

    final String accessToken =
        data["accessToken"]?.toString() ?? "";

    final String refreshToken =
        data["refreshToken"]?.toString() ?? "";

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw Exception("Tokens manquants dans la réponse login");
    }

    await storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> logout() async {
    await storage.clearTokens();
  }
}
