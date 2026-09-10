class AdminAcademicSessionModel {
  final String id;
  final String schoolId;
  final String session;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCurrent;
  final DateTime? createdAt;

  AdminAcademicSessionModel({
    required this.id,
    required this.schoolId,
    required this.session,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    this.createdAt,
  });

  factory AdminAcademicSessionModel.fromJson(Map<String, dynamic> json) {
    return AdminAcademicSessionModel(
      id: json['id']?.toString() ?? '',
      schoolId: json['schoolId']?.toString() ?? '',
      session: json['session']?.toString() ?? '',

      startDate: DateTime.parse(json['startDate'].toString()).toLocal(),

      endDate: DateTime.parse(json['endDate'].toString()).toLocal(),

      isCurrent: json['isCurrent'] == true,

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())?.toLocal()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'schoolId': schoolId,
      'session': session,
      'startDate': startDate.toUtc().toIso8601String(),
      'endDate': endDate.toUtc().toIso8601String(),
      'isCurrent': isCurrent,
      'createdAt': createdAt?.toUtc().toIso8601String(),
    };
  }

  AdminAcademicSessionModel copyWith({
    String? id,
    String? schoolId,
    String? session,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    DateTime? createdAt,
  }) {
    return AdminAcademicSessionModel(
      id: id ?? this.id,
      schoolId: schoolId ?? this.schoolId,
      session: session ?? this.session,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
