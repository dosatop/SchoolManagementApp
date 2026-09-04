class AdminEditStudentModel {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String studentNumber;
  final String classRoomId;

  final String? departmentId;
  final String? tradeId;
  final String? tradeSubjectId;

  AdminEditStudentModel({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.studentNumber,
    required this.classRoomId,
    this.departmentId,
    this.tradeId,
    this.tradeSubjectId,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber.isEmpty
          ? null
          : phoneNumber,
      'studentNumber': studentNumber,
      'classRoomId': classRoomId,

      'departmentId': departmentId,
      'tradeId': tradeId,
      'tradeSubjectId': tradeSubjectId,
    };
  }
}
