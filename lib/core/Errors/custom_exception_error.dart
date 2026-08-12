import 'package:dio/dio.dart';

class ApiErrorHandler {
  static String getCode(dynamic error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return "NETWORK_ERROR";
    }

    if (error.response != null) {
      final data = error.response.data;

      if (data is Map<String, dynamic>) {
        return data["code"] ?? "UNKNOWN_ERROR";
      }
    }

    if (error.message != null) {
      final message = error.message.toString();

      if (message.contains("SocketException")) {
        return "NO_INTERNET";
      }

      if (message.contains("timeout")) {
        return "TIMEOUT";
      }
    }

    return "UNKNOWN_ERROR";
  }
}
