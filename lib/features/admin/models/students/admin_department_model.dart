class AdminDepartmentModel {
  final String departmentId;
  final String departmentName;
  final String schoolId;

  const AdminDepartmentModel({
    required this.departmentId,
    required this.departmentName, required this.schoolId,
  });

  factory AdminDepartmentModel.fromJson(Map<String, dynamic> json) {
    return AdminDepartmentModel(
      departmentId: (json['departmentId'] ?? json['id'] ?? '').toString(),
      departmentName:
          (json['departmentName'] ?? json['name'] ?? '').toString(),
          schoolId: json['schoolId']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'departmentId': departmentId,
      'departmentName': departmentName,
      'schoolId': schoolId,
    };
  }
}
