class SchoolModel {
  final String id;
  final String name;
  final String address;
  final String email;
  final String phoneNumber;

  final int userCount;
  final int adminCount;
  final int teacherCount;
  final int studentCount;
  final int classCount;
  final int subjectCount;

  SchoolModel({
    required this.id,
    required this.name,
    required this.address,
    required this.email,
    required this.phoneNumber,
    required this.userCount,
    required this.adminCount,
    required this.teacherCount,
    required this.studentCount,
    required this.classCount,
    required this.subjectCount,
  });

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',

      userCount: (json['userCount'] as num?)?.toInt() ?? 0,
      adminCount: (json['adminCount'] as num?)?.toInt() ?? 0,
      teacherCount: (json['teacherCount'] as num?)?.toInt() ?? 0,
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
      classCount: (json['classCount'] as num?)?.toInt() ?? 0,
      subjectCount: (json['subjectCount'] as num?)?.toInt() ?? 0,
    );
  }
}
