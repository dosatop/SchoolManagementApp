class AdminStudentParentModel {
  final String parentId;
  final String parentName;
  final String email;
  final String phoneNumber;

  const AdminStudentParentModel({
    required this.parentId,
    required this.parentName,
    required this.email,
    required this.phoneNumber,
  });

  factory AdminStudentParentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminStudentParentModel(
      parentId: json['parentId']?.toString() ?? '',
      parentName: json['parentName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
    );
  }
}