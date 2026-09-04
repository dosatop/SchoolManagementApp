import 'package:app/core/Errors/custom_exception_error.dart';
import 'package:app/core/constants/api_constant.dart';
import 'package:app/core/storage/storage_service.dart';
import 'package:app/core/utils/app_logger.dart';
import 'package:dio/dio.dart';

class DioClient {
  final StorageService storageService;
  final Future<void> Function() onLogout;
  late final Dio dio;

  DioClient(this.storageService, this.onLogout) {
    dio = Dio(
      BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 30),
    persistentConnection: false,
        headers: {
          ApiConstants.accept: ApiConstants.applicationJson,
          ApiConstants.contentType: ApiConstants.applicationJson,
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storageService.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          AppLogger.logger.i('''
              REQUEST
              ${options.method} ${options.uri}
              Headers: ${options.headers}
              Data: ${options.data}
            ''');

          handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.logger.i('''
              REQUEST
              ${response.statusCode}
               ${response.requestOptions.uri}
              Data: ${response.data}
            ''');
          handler.next(response);
        },
        onError: (error, handler) async {
          AppLogger.logger.e('''
ERROR
${error.message}
${error.requestOptions.uri}
Response: ${error.response?.data}
''');

          // ============================================================
          // 401
          // ============================================================

          if (error.response?.statusCode == 401) {
            await onLogout();
          }

          // ============================================================
          // GLOBAL ERROR
          // ============================================================

          final appException = ApiErrorHandler.handle(error);

          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: appException,
            ),
          );
        },

        // Token expired / invalid
      ),
    );
  }
}
