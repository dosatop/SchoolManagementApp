class ParentModel {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String role;
  final String email;
  final String schoolId;
  final String schoolName;

  ParentModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.email,
    required this.schoolId,
    required this.schoolName,
  });

  factory ParentModel.fromJson(Map<String, dynamic> json) {
    return ParentModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      schoolId: json['schoolId']?.toString() ?? '',
      schoolName: json['schoolName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'role': role,
      'email': email,
      'schoolId': schoolId,
      'schoolName': schoolName,
    };
  }
}