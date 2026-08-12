class AppException implements Exception {
  final String code;

  AppException(this.code);

  @override
  String toString() => code;
}