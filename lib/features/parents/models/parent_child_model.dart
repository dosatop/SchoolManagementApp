class ParentChildModel {
  final String studentId;
  final String studentNumber;
  final String fullName;
  final String email;
  final String classId;
  final String className;

  ParentChildModel({
    required this.studentId,
    required this.studentNumber,
    required this.fullName,
    required this.email,
    required this.classId,
    required this.className,
  });

  factory ParentChildModel.fromJson(Map<String, dynamic> json) {
    return ParentChildModel(
      studentId: json['studentId']?.toString() ?? '',
      studentNumber: json['studentNumber']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      classId: json['classId']?.toString() ?? '',
      className: json['className']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentNumber': studentNumber,
      'fullName': fullName,
      'email': email,
      'classId': classId,
      'className': className,
    };
  }
}