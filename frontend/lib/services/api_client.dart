import 'package:dio/dio.dart';
import '../config/api.dart';
import 'secure_store.dart';

class ApiClient {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
  ApiClient() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStore.getToken();
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      },
    ));
  }
  Dio get dio => _dio;
}

final api = ApiClient().dio;
