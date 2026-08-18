class AdminParentChildModel {
  final String studentId;
  final String studentNumber;
  final String studentName;
  final String email;
  final String classId;
  final String className;

  const AdminParentChildModel({
    required this.studentId,
    required this.studentNumber,
    required this.studentName,
    required this.email,
    required this.classId,
    required this.className,
  });

  factory AdminParentChildModel.fromJson(Map<String, dynamic> json) {
    return AdminParentChildModel(
      studentId: json['studentId']?.toString() ?? '',
      studentNumber: json['studentNumber']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      classId: json['classId']?.toString() ?? '',
      className: json['className']?.toString() ?? '',
    );
  }
}

class AdminParentDetailModel {
  final String parentId;
  final String userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String schoolId;
  final List<AdminParentChildModel> children;

  const AdminParentDetailModel({
    required this.parentId,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.schoolId,
    required this.children,
  });

  factory AdminParentDetailModel.fromJson(Map<String, dynamic> json) {
    final childrenJson = json['children'];

    return AdminParentDetailModel(
      parentId: json['parentId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      schoolId: json['schoolId']?.toString() ?? '',
      children: childrenJson is List
          ? childrenJson
              .whereType<Map<String, dynamic>>()
              .map(AdminParentChildModel.fromJson)
              .toList()
          : [],
    );
  }
}