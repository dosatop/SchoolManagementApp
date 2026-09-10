class CurrentAcademicSessionModel {
  final String id;
  final String schoolId;
  final String session;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;
  final DateTime createdAt;

  CurrentAcademicSessionModel({
    required this.id,
    required this.schoolId,
    required this.session,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    required this.createdAt,
  });

  factory CurrentAcademicSessionModel.fromJson(Map<String, dynamic> json) {
    return CurrentAcademicSessionModel(
      id: json['id']?.toString() ?? '',
      schoolId: json['schoolId']?.toString() ?? '',
      session: json['session']?.toString() ?? '',
      startDate: DateTime.parse(json['startDate'].toString()),
      endDate: DateTime.parse(json['endDate'].toString()),
      isCurrent: json['isCurrent'] == true,
      createdAt: DateTime.parse(json['createdAt'].toString()),
    );
  }
}
