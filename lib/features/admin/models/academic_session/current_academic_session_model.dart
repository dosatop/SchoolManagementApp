class CurrentAcademicSessionModel {
  final String id;
  final String schoolId;
  final String session;
  final String term;
  final bool isCurrent;
  final DateTime createdAt;

  CurrentAcademicSessionModel({
    required this.id,
    required this.schoolId,
    required this.session,
    required this.term,
    required this.isCurrent,
    required this.createdAt,
  });

  factory CurrentAcademicSessionModel.fromJson(Map<String, dynamic> json) {
    return CurrentAcademicSessionModel(
      id: json['id'] ?? '',
      schoolId: json['schoolId'] ?? '',
      session: json['session'] ?? '',
      term: json['term'] ?? '',
      isCurrent: json['isCurrent'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
