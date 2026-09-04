class AdminSubjectModel {
  final String subjectId;
  final String schoolId;
  final String subjectName;
  final String code;

  // ================================================================
  // TYPE
  // ================================================================

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

  factory AdminSubjectModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminSubjectModel(
      subjectId:
          json['subjectId']?.toString() ??
          json['id']?.toString() ??
          '',

      schoolId:
          json['schoolId']?.toString() ?? '',

      subjectName:
          json['subjectName']?.toString() ??
          json['name']?.toString() ??
          '',

      code:
          json['code']?.toString() ?? '',

      // ============================================================
      // TYPE
      // ============================================================

      type: json['type'] is int
          ? json['type']
          : int.tryParse(
              json['type']?.toString() ?? '',
            ),

      // ============================================================
      // DEPARTMENT
      // ============================================================

      departmentId:
          json['departmentId']?.toString(),

      departmentName:
          json['departmentName']?.toString(),

      // ============================================================
      // TRADE
      // ============================================================

      tradeId:
          json['tradeId']?.toString(),

      tradeName:
          json['tradeName']?.toString(),

      // ============================================================
      // TEACHERS
      // ============================================================

      teacherSubjects:
          (json['teacherSubjects'] as List? ?? [])
              .map(
                (item) =>
                    AdminSubjectTeacherModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
    );
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

      'teacherSubjects':
          teacherSubjects
              .map((teacher) => teacher.toJson())
              .toList(),
    };
  }

  // ================================================================
  // COPY WITH
  // ================================================================

  AdminSubjectModel copyWith({
    String? subjectId,
    String? schoolId,
    String? subjectName,
    String? code,

    int? type,

    String? departmentId,
    String? departmentName,

    String? tradeId,
    String? tradeName,

    List<AdminSubjectTeacherModel>? teacherSubjects,
  }) {
    return AdminSubjectModel(
      subjectId:
          subjectId ?? this.subjectId,

      schoolId:
          schoolId ?? this.schoolId,

      subjectName:
          subjectName ?? this.subjectName,

      code:
          code ?? this.code,

      type:
          type ?? this.type,

      departmentId:
          departmentId ?? this.departmentId,

      departmentName:
          departmentName ?? this.departmentName,

      tradeId:
          tradeId ?? this.tradeId,

      tradeName:
          tradeName ?? this.tradeName,

      teacherSubjects:
          teacherSubjects ?? this.teacherSubjects,
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

  factory AdminSubjectTeacherModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminSubjectTeacherModel(
      assignmentId:
          json['assignmentId']?.toString() ?? '',

      teacherId:
          json['teacherId']?.toString() ?? '',

      teacherName:
          json['teacherName']?.toString() ?? '',

      email:
          json['email']?.toString() ?? '',

      subjectId:
          json['subjectId']?.toString() ?? '',

      subjectName:
          json['subjectName']?.toString() ?? '',

      subjectCode:
          json['subjectCode']?.toString() ?? '',

      classId:
          json['classId']?.toString() ?? '',

      className:
          json['className']?.toString() ?? '',
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
