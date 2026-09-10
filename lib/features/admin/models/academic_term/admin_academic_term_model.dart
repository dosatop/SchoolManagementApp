class AdminAcademicTermModel {
  final String id;
  final String academicSessionId;
  final String term;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;

  AdminAcademicTermModel({
    required this.id,
    required this.academicSessionId,
    required this.term,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
  });

  factory AdminAcademicTermModel.fromJson(Map<String, dynamic> json) {
    return AdminAcademicTermModel(
      id: json['id'] as String,
      academicSessionId: json['academicSessionId'] as String,
      term: json['term'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'academicSessionId': academicSessionId,
      'term': term,
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
      'isCurrent': isCurrent,
    };
  }
}
