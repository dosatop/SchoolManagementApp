class AdminCreateStudentModel {
  final String fullName;
  final String email;
  final String password;
  final String studentNumber;
  final String? departmentId;
  final String? tradeId;
  final String? tradeSubjectId;
  final String classRoomId;

  const AdminCreateStudentModel({
    required this.fullName,
    required this.email,
    required this.password,
    required this.studentNumber,
    this.departmentId,
    this.tradeId,
      this.tradeSubjectId,
    required this.classRoomId,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'password': password,
      'studentNumber': studentNumber,
      'departmentId': departmentId,
      'tradeId': tradeId,
      'tradeSubjectId': tradeSubjectId,
      'classRoomId': classRoomId,
    };
  }
}
