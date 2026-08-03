class ApiException implements Exception {
  final String message;
  const ApiException([this.message = 'An unexpected error occurred.']);
}

class NetworkException extends ApiException {
  const NetworkException.noInternet()
      : super('No internet connection. Please check your network.');

  const NetworkException.timeout()
      : super('Request timed out. Please try again.');

  const NetworkException.generic()
      : super('A network error occurred.');
}

class ValidationException extends ApiException {
  const ValidationException([super.message]);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message]);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([super.message]);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message]);
}

class ConflictException extends ApiException {
  const ConflictException([super.message]);
}

class ServerException extends ApiException {
  const ServerException([super.message = 'Internal server error.']);
}