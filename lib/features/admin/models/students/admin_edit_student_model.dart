class AdminEditStudentModel {
  final String fullName;
  final String email;
  final String phoneNumber;
  final String studentNumber;
  final String classRoomId;

  const AdminEditStudentModel({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.studentNumber,
    required this.classRoomId,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'studentNumber': studentNumber,
      'classRoomId': classRoomId,
    };
  }
}