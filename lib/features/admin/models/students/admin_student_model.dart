class AdminStudentModel {
  // ================================================================
  // IDENTIFICATION
  // ================================================================

  final String studentId;
  final String studentNumber;
  final String studentName;

  // ================================================================
  // SCHOOL
  // ================================================================

  final String schoolId;
  final String schoolName;

  // ================================================================
  // CLASS
  // ================================================================

  final String? classId;
  final String className;

  // ================================================================
  // SCHOOL LEVEL
  // ================================================================

  final String schoolLevel;
  final int schoolLevelId;

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
  // TRADE SUBJECT
  // ================================================================

  final String? tradeSubjectId;
  final String? tradeSubjectName;
  final String? tradeSubjectCode;

  // ================================================================
  // CONTACT
  // ================================================================

  final String? email;
  final String? phoneNumber;

  // ================================================================
  // PARENTS
  // ================================================================

  final int parentCount;

  const AdminStudentModel({
    required this.studentId,
    required this.studentNumber,
    required this.studentName,

    required this.schoolId,
    required this.schoolName,

    this.classId,
    required this.className,

    required this.schoolLevel,
    required this.schoolLevelId,

    this.departmentId,
    this.departmentName,

    this.tradeId,
    this.tradeName,

    this.tradeSubjectId,
    this.tradeSubjectName,
    this.tradeSubjectCode,

    this.email,
    this.phoneNumber,

    required this.parentCount,
  });

  // ================================================================
  // FROM JSON
  // ================================================================

  factory AdminStudentModel.fromJson(Map<String, dynamic> json) {
    return AdminStudentModel(
      // ------------------------------------------------------------
      // IDENTIFICATION
      // ------------------------------------------------------------
      studentId: json['studentId']?.toString() ?? '',

      studentNumber: json['studentNumber']?.toString() ?? '',

      studentName: json['studentName']?.toString() ?? '',

      // ------------------------------------------------------------
      // SCHOOL
      // ------------------------------------------------------------
      schoolId: json['schoolId']?.toString() ?? '',

      schoolName: json['schoolName']?.toString() ?? '',

      // ------------------------------------------------------------
      // CLASS
      // ------------------------------------------------------------
      classId: json['classId']?.toString(),

      className: json['className']?.toString() ?? '',

      // ------------------------------------------------------------
      // SCHOOL LEVEL
      // ------------------------------------------------------------
      schoolLevel: json['schoolLevel']?.toString() ?? '',

      schoolLevelId: int.tryParse(json['schoolLevelId']?.toString() ?? '') ?? 0,

      // ------------------------------------------------------------
      // DEPARTMENT
      // ------------------------------------------------------------
      departmentId: json['departmentId']?.toString(),

      departmentName: json['departmentName']?.toString(),

      // ------------------------------------------------------------
      // TRADE
      // ------------------------------------------------------------
      tradeId: json['tradeId']?.toString(),

      tradeName: json['tradeName']?.toString(),

      // ------------------------------------------------------------
      // TRADE SUBJECT
      // ------------------------------------------------------------
      tradeSubjectId: json['tradeSubjectId']?.toString(),

      tradeSubjectName: json['tradeSubjectName']?.toString(),

      tradeSubjectCode: json['tradeSubjectCode']?.toString(),

      // ------------------------------------------------------------
      // CONTACT
      // ------------------------------------------------------------
      email: json['email']?.toString(),

      phoneNumber: json['phoneNumber']?.toString(),

      // ------------------------------------------------------------
      // PARENTS
      // ------------------------------------------------------------
      parentCount: int.tryParse(json['parentCount']?.toString() ?? '') ?? 0,
    );
  }

  // ================================================================
  // TO JSON
  // ================================================================

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentNumber': studentNumber,
      'studentName': studentName,

      'schoolId': schoolId,
      'schoolName': schoolName,

      'classId': classId,
      'className': className,

      'schoolLevel': schoolLevel,
      'schoolLevelId': schoolLevelId,

      'departmentId': departmentId,
      'departmentName': departmentName,

      'tradeId': tradeId,
      'tradeName': tradeName,

      'tradeSubjectId': tradeSubjectId,
      'tradeSubjectName': tradeSubjectName,
      'tradeSubjectCode': tradeSubjectCode,

      'email': email,
      'phoneNumber': phoneNumber,

      'parentCount': parentCount,
    };
  }

  // ================================================================
  // COPY WITH
  // ================================================================

  AdminStudentModel copyWith({
    String? studentId,
    String? studentNumber,
    String? studentName,

    String? schoolId,
    String? schoolName,

    String? classId,
    String? className,

    String? schoolLevel,
    int? schoolLevelId,

    String? departmentId,
    String? departmentName,

    String? tradeId,
    String? tradeName,

    String? tradeSubjectId,
    String? tradeSubjectName,
    String? tradeSubjectCode,

    String? email,
    String? phoneNumber,

    int? parentCount,
  }) {
    return AdminStudentModel(
      studentId: studentId ?? this.studentId,

      studentNumber: studentNumber ?? this.studentNumber,

      studentName: studentName ?? this.studentName,

      schoolId: schoolId ?? this.schoolId,

      schoolName: schoolName ?? this.schoolName,

      classId: classId ?? this.classId,

      className: className ?? this.className,

      schoolLevel: schoolLevel ?? this.schoolLevel,

      schoolLevelId: schoolLevelId ?? this.schoolLevelId,

      departmentId: departmentId ?? this.departmentId,

      departmentName: departmentName ?? this.departmentName,

      tradeId: tradeId ?? this.tradeId,

      tradeName: tradeName ?? this.tradeName,

      tradeSubjectId: tradeSubjectId ?? this.tradeSubjectId,

      tradeSubjectName: tradeSubjectName ?? this.tradeSubjectName,

      tradeSubjectCode: tradeSubjectCode ?? this.tradeSubjectCode,

      email: email ?? this.email,

      phoneNumber: phoneNumber ?? this.phoneNumber,

      parentCount: parentCount ?? this.parentCount,
    );
  }
}
