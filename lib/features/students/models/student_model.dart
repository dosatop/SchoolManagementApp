class StudentModel {
  final String studentId;
  final String userId;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final String studentNumber;
  final String schoolId;
  final String schoolName;
  final String classId;
  final String className;

  StudentModel({
    required this.studentId,
    required this.userId,
    required this.fullName,
    this.email,
    this.phoneNumber,
    required this.studentNumber,
    required this.schoolId,
    required this.schoolName,
    required this.classId,
    required this.className,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      studentId: json['studentId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      studentNumber: json['studentNumber']?.toString() ?? '',
      schoolId: json['schoolId']?.toString() ?? '',
      schoolName: json['schoolName']?.toString() ?? '',
      classId: json['classId']?.toString() ?? '',
      className: json['className']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'studentNumber': studentNumber,
      'schoolId': schoolId,
      'schoolName': schoolName,
      'classId': classId,
      'className': className,
    };
  }
}