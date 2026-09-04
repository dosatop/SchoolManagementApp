
class AdminGetClassSubjectModel {
  final String classSubjectId;
  final String subjectId;
  final String subjectName;
  final String subjectCode;
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
      classSubjectId: json['classSubjectId'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      subjectName: json['subjectName'] as String? ?? '',
      subjectCode: json['subjectCode'] as String? ?? '',
      subjectType: json['subjectType'] as int? ?? 0,
      departmentId: json['departmentId'] as String?,
      departmentName: json['departmentName'] as String?,
      tradeId: json['tradeId'] as String?,
      tradeName: json['tradeName'] as String?,
      classId: json['classId'] as String? ?? '',
      className: json['className'] as String? ?? '',
    );
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



