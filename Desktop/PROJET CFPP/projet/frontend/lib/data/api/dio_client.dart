import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../services/storage_service.dart';

class DioClient {
  final StorageService storage;
  late final Dio dio;

  DioClient({required this.storage}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: Duration(milliseconds: ApiConstants.connectTimeoutMs),
        receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeoutMs),
        headers: {
          "Content-Type": "application/json",
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers["Authorization"] = "Bearer $token";
          }
          handler.next(options);
        },
      ),
    );
  }
}
