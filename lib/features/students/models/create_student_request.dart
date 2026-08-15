class CreateStudentRequest {
  final String fullName;
  final String email;
  final String password;
  final String studentNumber;
  final String classRoomId;

  CreateStudentRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.studentNumber,
    required this.classRoomId,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'password': password,
      'studentNumber': studentNumber,
      'classRoomId': classRoomId,
    };
  }
}