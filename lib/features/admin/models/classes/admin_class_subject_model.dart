class AdminClassSubjectModel {
  final String classSubjectId;
  final String schoolId;
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final int subjectType;
  final String? departmentId;
  final String? departmentName;
  final String? tradeId;
  final String? tradeName;
  final String? message;

  const AdminClassSubjectModel({
    required this.classSubjectId,
    required this.schoolId,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.subjectType,
    this.departmentId,
    this.departmentName,
    this.tradeId,
    this.tradeName,
    this.message,
  });

  factory AdminClassSubjectModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminClassSubjectModel(
      classSubjectId: json['classSubjectId'] as String,
      schoolId: json['schoolId'] as String,
      classId: json['classId'] as String,
      className: json['className'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      subjectCode: json['subjectCode'] as String,
      subjectType: json['subjectType'] as int,
      departmentId: json['departmentId'] as String?,
      departmentName: json['departmentName'] as String?,
      tradeId: json['tradeId'] as String?,
      tradeName: json['tradeName'] as String?,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'classSubjectId': classSubjectId,
      'schoolId': schoolId,
      'classId': classId,
      'className': className,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'subjectCode': subjectCode,
      'subjectType': subjectType,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'tradeId': tradeId,
      'tradeName': tradeName,
      'message': message,
    };
  }
}
