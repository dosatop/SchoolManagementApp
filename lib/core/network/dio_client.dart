import 'package:app/core/Errors/custom_exception_error.dart';
import 'package:app/core/constants/api_constant.dart';
import 'package:app/core/storage/storage_service.dart';
import 'package:app/core/utils/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
        // Reusing connections is much faster (no new TLS handshake per
        // request). Only set false if your server/proxy breaks keep-alive.
        persistentConnection: true,
        headers: {
          ApiConstants.accept: ApiConstants.applicationJson,
          ApiConstants.contentType: ApiConstants.applicationJson,
        },
      ),
    );

    _setupInterceptors();
  }

  // Only one logout even if many requests get 401 at the same time.
  Future<void>? _loggingOut;

  // Requests where 401 means "wrong details", not "session expired".
  static const _noLogoutPaths = ['/auth/login', '/login', '/auth/logout', '/logout'];

  bool _isAuthRequest(RequestOptions options) {
    final path = options.path.toLowerCase();
    return _noLogoutPaths.any(path.contains);
  }

  // ================================================================
  // LOGGING (debug only, trimmed, no secrets)
  // ================================================================

  static const int _maxLogChars = 800;

  String _short(Object? data) {
    if (data == null) return 'null';
    final text = data.toString();
    if (text.length <= _maxLogChars) return text;
    return '${text.substring(0, _maxLogChars)}… (${text.length} chars)';
  }

  Map<String, dynamic> _safeHeaders(Map<String, dynamic> headers) {
    final copy = Map<String, dynamic>.from(headers);
    if (copy.containsKey('Authorization')) copy['Authorization'] = 'Bearer ***';
    return copy;
  }

  Object? _safeBody(Object? data) {
    if (data is Map) {
      final copy = Map<String, dynamic>.from(data);
      for (final key in ['password', 'confirmPassword', 'newPassword']) {
        if (copy.containsKey(key)) copy[key] = '***';
      }
      return copy;
    }
    return data;
  }

  // ================================================================
  // INTERCEPTORS
  // ================================================================

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storageService.getToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (kDebugMode) {
            AppLogger.logger.i(
              '→ ${options.method} ${options.uri}\n'
              'Headers: ${_safeHeaders(options.headers)}\n'
              'Data: ${_short(_safeBody(options.data))}',
            );
          }

          handler.next(options);
        },

        onResponse: (response, handler) {
          if (kDebugMode) {
            AppLogger.logger.i(
              '← ${response.statusCode} ${response.requestOptions.uri}\n'
              'Data: ${_short(response.data)}',
            );
          }

          handler.next(response);
        },

        onError: (error, handler) async {
          if (kDebugMode) {
            AppLogger.logger.e(
              '✕ ${error.response?.statusCode ?? error.type.name} '
              '${error.requestOptions.uri}\n'
              '${error.message}\n'
              'Response: ${_short(error.response?.data)}',
            );
          }

                   // ----------------------------------------------------------
          // 401 → session expired → log out (once)
          // ----------------------------------------------------------
          // Only if this request used the CURRENT token. A late 401 from
          // the previous account (or a request sent with no token) must
          // not wipe the session of the account that just logged in.
          if (error.response?.statusCode == 401 &&
              !_isAuthRequest(error.requestOptions)) {
            final sentHeader =
                error.requestOptions.headers['Authorization']?.toString();
            final currentToken = await storageService.getToken();

            final sentWithCurrentToken =
                currentToken != null &&
                currentToken.isNotEmpty &&
                sentHeader == 'Bearer $currentToken';

            if (sentWithCurrentToken) {
              await storageService.clearAuth();
              _loggingOut ??= onLogout().whenComplete(() => _loggingOut = null);
              await _loggingOut;
            }
          }

          // ----------------------------------------------------------
          // Global error
          // ----------------------------------------------------------
          final appException = ApiErrorHandler.handle(error);

          return handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: appException,
              message: appException.toString(),
            ),
          );
        },
      ),
    );
  }
}