import 'package:app/core/Errors/app_exception.dart';
import 'package:dio/dio.dart';

class ApiErrorHandler {
  static AppException handle(DioException error) {
    // ============================================================
    // NETWORK ERRORS
    // ============================================================

    if (error.type == DioExceptionType.connectionError) {
      return const AppException(
        code: 'NETWORK_ERROR',
        message: 'No internet connection.',
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const AppException(
        code: 'TIMEOUT',
        message: 'The request timed out. Please try again.',
      );
    }

    // ============================================================
    // SERVER RESPONSE
    // ============================================================

    final data = error.response?.data;

    if (data is Map) {
      final code = data['code']?.toString() ?? 'UNKNOWN_ERROR';

      final message =
          data['message']?.toString() ??
          data['error']?.toString() ??
          'Something went wrong. Please try again.';

      return AppException(
        code: code,
        message: message,
      );
    }

    // ============================================================
    // DIO MESSAGE
    // ============================================================

    if (error.message != null && error.message!.isNotEmpty) {
      return AppException(
        code: 'UNKNOWN_ERROR',
        message: error.message!,
      );
    }

    return const AppException(
      code: 'UNKNOWN_ERROR',
      message: 'Something went wrong. Please try again.',
    );
  }
}
