class AdminSubjectModel {
  final String subjectId;
  final String schoolId;
  final String subjectName;
  final String code;

  // ================================================================
  // TYPE
  // ================================================================
  // 1 = General, 2 = Department, 3 = Trade. Null if unknown.

  final int? type;

  // ================================================================
  // DEPARTMENT
  // ================================================================

  final String? departmentId;
  final String? departmentName;

  // ================================================================
  // TRADE
  // ================================================================

  final String? tradeId;
  final String? tradeName;

  // ================================================================
  // TEACHERS
  // ================================================================

  final List<AdminSubjectTeacherModel> teacherSubjects;

  const AdminSubjectModel({
    required this.subjectId,
    required this.schoolId,
    required this.subjectName,
    required this.code,
    this.type,
    this.departmentId,
    this.departmentName,
    this.tradeId,
    this.tradeName,
    required this.teacherSubjects,
  });

  // ================================================================
  // FROM JSON
  // ================================================================

  factory AdminSubjectModel.fromJson(Map<String, dynamic> json) {
    final departmentId = _toStr(json['departmentId']);
    final tradeId = _toStr(json['tradeId']);

    // The API sends the type as an enum name ("General",
    // "Departmental", "Trade"). Accept that, numbers, and "1".
    var type = _toType(json['type'] ?? json['subjectType']);

    // Still unknown? Work it out from what the subject belongs to.
    type ??= tradeId != null
        ? 3
        : departmentId != null
        ? 2
        : null;

    return AdminSubjectModel(
      subjectId: _toStr(json['subjectId'] ?? json['id']) ?? '',
      schoolId: _toStr(json['schoolId']) ?? '',
      subjectName: _toStr(json['subjectName'] ?? json['name']) ?? '',
      code: _toStr(json['code'] ?? json['subjectCode']) ?? '',
      type: type,
      departmentId: departmentId,
      departmentName: _toStr(json['departmentName']),
      tradeId: tradeId,
      tradeName: _toStr(json['tradeName']),
      teacherSubjects: (json['teacherSubjects'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => AdminSubjectTeacherModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  /// Readable label for the UI.
  String get typeName {
    switch (type) {
      case 1:
        return 'General';
      case 2:
        return 'Department';
      case 3:
        return 'Trade';
      default:
        return 'Uncategorised';
    }
  }

  // ================================================================
  // TO JSON
  // ================================================================

  Map<String, dynamic> toJson() {
    return {
      'subjectId': subjectId,
      'schoolId': schoolId,
      'subjectName': subjectName,
      'code': code,
      'type': type,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'tradeId': tradeId,
      'tradeName': tradeName,
      'teacherSubjects': teacherSubjects.map((t) => t.toJson()).toList(),
    };
  }

  // ================================================================
  // COPY WITH
  // ================================================================
  // The nullable fields use a sentinel so you CAN set them to null,
  // e.g. when a Department subject is changed to General:
  //   subject.copyWith(type: 1, departmentId: null, departmentName: null)

  static const Object _keep = Object();

  AdminSubjectModel copyWith({
    String? subjectId,
    String? schoolId,
    String? subjectName,
    String? code,
    Object? type = _keep,
    Object? departmentId = _keep,
    Object? departmentName = _keep,
    Object? tradeId = _keep,
    Object? tradeName = _keep,
    List<AdminSubjectTeacherModel>? teacherSubjects,
  }) {
    return AdminSubjectModel(
      subjectId: subjectId ?? this.subjectId,
      schoolId: schoolId ?? this.schoolId,
      subjectName: subjectName ?? this.subjectName,
      code: code ?? this.code,
      type: identical(type, _keep) ? this.type : type as int?,
      departmentId: identical(departmentId, _keep)
          ? this.departmentId
          : departmentId as String?,
      departmentName: identical(departmentName, _keep)
          ? this.departmentName
          : departmentName as String?,
      tradeId: identical(tradeId, _keep) ? this.tradeId : tradeId as String?,
      tradeName: identical(tradeName, _keep)
          ? this.tradeName
          : tradeName as String?,
      teacherSubjects: teacherSubjects ?? this.teacherSubjects,
    );
  }
}

// ==================================================================
// SUBJECT TEACHER
// ==================================================================

class AdminSubjectTeacherModel {
  final String assignmentId;
  final String teacherId;
  final String teacherName;
  final String email;
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String classId;
  final String className;

  const AdminSubjectTeacherModel({
    required this.assignmentId,
    required this.teacherId,
    required this.teacherName,
    required this.email,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.classId,
    required this.className,
  });

  factory AdminSubjectTeacherModel.fromJson(Map<String, dynamic> json) {
    return AdminSubjectTeacherModel(
      assignmentId: _toStr(json['assignmentId'] ?? json['id']) ?? '',
      teacherId: _toStr(json['teacherId']) ?? '',
      teacherName: _toStr(json['teacherName']) ?? '',
      email: _toStr(json['email']) ?? '',
      subjectId: _toStr(json['subjectId']) ?? '',
      subjectName: _toStr(json['subjectName']) ?? '',
      subjectCode: _toStr(json['subjectCode']) ?? '',
      classId: _toStr(json['classId']) ?? '',
      className: _toStr(json['className']) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignmentId': assignmentId,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'email': email,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'classId': classId,
      'className': className,
    };
  }
}

// ==================================================================
// PARSING HELPERS (private to this file)
// ==================================================================

/// 1 / "1" / "General" -> 1, "Department(al)" -> 2, "Trade" -> 3.
int? _toType(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();

  final text = value.toString().trim();
  final parsed = int.tryParse(text);
  if (parsed != null) return parsed;

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

/// Any value -> trimmed string, or null if empty.
String? _toStr(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  return s.isEmpty ? null : s;
}
