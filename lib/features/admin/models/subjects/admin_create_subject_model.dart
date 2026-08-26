class AdminCreateSubjectModel {
  final String name;
  final String code;

  const AdminCreateSubjectModel({
    required this.name,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
    };
  }
}

// ==================================================================
// CLASS SUBJECT
// ==================================================================

class AdminClassSubjectModel {
  final String subjectId;
  final String subjectName;
  final String subjectCode;

  const AdminClassSubjectModel({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
  });

  factory AdminClassSubjectModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminClassSubjectModel(
      subjectId: json['subjectId'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      subjectCode: json['subjectCode'] as String? ?? '',
    );
  }
}