import 'package:app/core/Errors/app_exception.dart';
import 'package:dio/dio.dart';

class ApiErrorHandler {
  static AppException handle(DioException error) {
    // ============================================================
    // ALREADY HANDLED
    // ============================================================
    // DioClient's interceptor converts the error once; repositories
    // call handle() again. Keep the first result.

    if (error.error is AppException) return error.error as AppException;

    // ============================================================
    // NETWORK ERRORS
    // ============================================================

    switch (error.type) {
      case DioExceptionType.connectionError:
        return const AppException(
          code: 'NETWORK_ERROR',
          message: 'No internet connection. Check your network and try again.',
        );
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const AppException(
          code: 'TIMEOUT',
          message: 'The server took too long to respond. Please try again.',
        );
      case DioExceptionType.cancel:
        return const AppException(
          code: 'CANCELLED',
          message: 'The request was cancelled.',
        );
      case DioExceptionType.badCertificate:
        return const AppException(
          code: 'BAD_CERTIFICATE',
          message: 'Secure connection failed. Please try again later.',
        );
      default:
        break;
    }

    // ============================================================
    // SERVER RESPONSE
    // ============================================================

    final status = error.response?.statusCode;
    final data = error.response?.data;

    final message = _extractMessage(data);
    final code = _extractCode(data) ?? _codeForStatus(status);

    return AppException(
      code: code,
      message: message ?? _messageForStatus(status),
    );
  }

  // ==============================================================
  // MESSAGE FROM ANY BODY SHAPE
  // ==============================================================
  //   "plain text"
  //   { message } / { Message } / { error } / { detail } / { title }
  //   { errors: [ { code, message } ] }       ← ServiceError list
  //   { errors: { Field: ["msg", ...] } }    ← ASP.NET validation
  //   { data: { ...any of the above } }

  static String? _extractMessage(dynamic data) {
    if (data == null) return null;

    if (data is String) {
      final s = data.trim();
      // Ignore empty bodies and HTML error pages.
      return s.isEmpty || s.startsWith('<') ? null : s;
    }

    if (data is! Map) return null;

    final errors = data['errors'] ?? data['Errors'];

    // [ { code, message } ]
    if (errors is List) {
      final messages = errors
          .map(
            (e) => e is Map
                ? (e['message'] ?? e['Message'] ?? e['description'])
                : e,
          )
          .whereType<String>()
          .map((m) => m.trim())
          .where((m) => m.isNotEmpty)
          .toList();
      if (messages.isNotEmpty) return messages.join('\n');
    }

    // { Field: ["msg"] }  (model validation)
    if (errors is Map) {
      final messages = <String>[];
      for (final v in errors.values) {
        if (v is List) messages.addAll(v.whereType<String>());
        if (v is String) messages.add(v);
      }
      if (messages.isNotEmpty) return messages.join('\n');
    }

    // Simple keys. "title" last: for validation errors it's the
    // generic "One or more validation errors occurred."
    for (final key in ['message', 'Message', 'error', 'detail', 'title']) {
      final v = data[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }

    if (data['data'] is Map) return _extractMessage(data['data']);

    return null;
  }

  static String? _extractCode(dynamic data) {
    if (data is! Map) return null;

    final direct = data['code'] ?? data['Code'];
    if (direct != null && '$direct'.trim().isNotEmpty) return '$direct';

    final errors = data['errors'] ?? data['Errors'];
    if (errors is List && errors.isNotEmpty && errors.first is Map) {
      final c = (errors.first as Map)['code'] ?? (errors.first as Map)['Code'];
      if (c != null && '$c'.trim().isNotEmpty) return '$c';
    }

    return null;
  }

  // ==============================================================
  // FALLBACKS BY STATUS CODE (when the body has no message)
  // ==============================================================

  static String _codeForStatus(int? status) {
    switch (status) {
      case 400:
        return 'BAD_REQUEST';
      case 401:
        return 'UNAUTHORIZED';
      case 403:
        return 'FORBIDDEN';
      case 404:
        return 'NOT_FOUND';
      case 409:
        return 'CONFLICT';
      case 422:
        return 'VALIDATION_ERROR';
      default:
        return status != null && status >= 500
            ? 'SERVER_ERROR'
            : 'UNKNOWN_ERROR';
    }
  }

  static String _messageForStatus(int? status) {
    switch (status) {
      case 400:
        return 'Some details are not valid. Please check and try again.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You don\'t have permission to do this.';
      case 404:
        return 'We couldn\'t find what you were looking for.';
      case 409:
        return 'This already exists.';
      case 422:
        return 'Some details are not valid. Please check and try again.';
      case 429:
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        if (status != null && status >= 500) {
          return 'The server had a problem. Please try again shortly.';
        }
        return 'Something went wrong. Please try again.';
    }
  }
}