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
        receiveTimeout: const Duration(seconds: 30),
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

          if (error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                type: error.type,
                error: 'NETWORK_ERROR',
                message: 'No internet connection',
              ),
            );
          }
          handler.next(error);
        },
      ),
    );
  }
}
