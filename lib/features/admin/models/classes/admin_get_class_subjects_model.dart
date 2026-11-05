class AdminGetClassSubjectModel {
  final String classSubjectId;
  final String subjectId;
  final String subjectName;
  final String subjectCode;

  /// 1 = General, 2 = Department, 3 = Trade, 0 = unknown.
  final int subjectType;

  final String? departmentId;
  final String? departmentName;
  final String? tradeId;
  final String? tradeName;
  final String classId;
  final String className;

  const AdminGetClassSubjectModel({
    required this.classSubjectId,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.subjectType,
    this.departmentId,
    this.departmentName,
    this.tradeId,
    this.tradeName,
    required this.classId,
    required this.className,
  });

  factory AdminGetClassSubjectModel.fromJson(Map<String, dynamic> json) {
    return AdminGetClassSubjectModel(
      classSubjectId: _toStr(json['classSubjectId'] ?? json['id']) ?? '',
      subjectId: _toStr(json['subjectId']) ?? '',
      subjectName: _toStr(json['subjectName'] ?? json['name']) ?? '',
      subjectCode: _toStr(json['subjectCode'] ?? json['code']) ?? '',

      // The API sends this as an enum name ("General") — that was the
      // crash. _toInt accepts numbers, "1", or the name.
      subjectType: _toInt(json['subjectType'] ?? json['type']) ?? 0,

      departmentId: _toStr(json['departmentId']),
      departmentName: _toStr(json['departmentName']),
      tradeId: _toStr(json['tradeId']),
      tradeName: _toStr(json['tradeName']),
      classId: _toStr(json['classId']) ?? '',
      className: _toStr(json['className']) ?? '',
    );
  }

  /// Readable label for the UI.
  String get subjectTypeName {
    switch (subjectType) {
      case 1:
        return 'General';
      case 2:
        return 'Department';
      case 3:
        return 'Trade';
      default:
        return 'Subject';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'classSubjectId': classSubjectId,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'subjectType': subjectType,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'tradeId': tradeId,
      'tradeName': tradeName,
      'classId': classId,
      'className': className,
    };
  }
}

// ==================================================================
// PARSING HELPERS (private to this file)
// ==================================================================

/// Accepts 1, 1.0, "1", or an enum name like "General".
int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();

  final text = value.toString().trim();
  final parsed = int.tryParse(text);
  if (parsed != null) return parsed;

  // Subject type sent as an enum name.
  switch (text.toLowerCase()) {
    case 'general':
      return 1;
    case 'department':
    case 'departmental':
      return 2;
    case 'trade':
      return 3;
  }
  return null;
}

/// Accepts a String, a Guid/number (via toString), or null.
String? _toStr(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}