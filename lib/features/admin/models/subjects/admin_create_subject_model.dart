class AdminCreateSubjectModel {
  final String name;
  final String code;

  // ================================================================
  // SUBJECT TYPE
  // ================================================================
  //
  // 1 = General
  // 2 = Departmental
  // 3 = Trade
  //
  final int type;

  // ================================================================
  // DEPARTMENT
  // ================================================================

  final String? departmentId;

  // ================================================================
  // TRADE
  // ================================================================

  final String? tradeId;

  const AdminCreateSubjectModel({
    required this.name,
    required this.code,
    required this.type,
    this.departmentId,
    this.tradeId,
  });

  // ================================================================
  // TO JSON
  // ================================================================

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'type': type,
      'departmentId': departmentId,
      'tradeId': tradeId,
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

  factory AdminClassSubjectModel.fromJson(Map<String, dynamic> json) {
    return AdminClassSubjectModel(
      subjectId: json['subjectId']?.toString() ?? '',

      subjectName: json['subjectName']?.toString() ?? '',

      subjectCode: json['subjectCode']?.toString() ?? '',
    );
  }
}
