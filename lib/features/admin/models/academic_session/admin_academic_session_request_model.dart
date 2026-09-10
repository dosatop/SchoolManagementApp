class AdminAcademicSessionRequestModel {
  final String session;
  final DateTime startDate;
  final DateTime endDate;

  AdminAcademicSessionRequestModel({
    required this.session,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'session': session,
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
    };
  }
}
