class AdminDashboardModel {
  final String schoolId;
  final String schoolName;

  final int userCount;
  final int adminCount;
  final int teacherCount;
  final int studentCount;
  final int classCount;
  final int subjectCount;

  AdminDashboardModel({
    required this.schoolId,
    required this.schoolName,
    required this.userCount,
    required this.adminCount,
    required this.teacherCount,
    required this.studentCount,
    required this.classCount,
    required this.subjectCount,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      schoolId: json['schoolId']?.toString() ?? '',
      schoolName: json['schoolName']?.toString() ?? '',
      userCount: (json['userCount'] as num?)?.toInt() ?? 0,
      adminCount: (json['adminCount'] as num?)?.toInt() ?? 0,
      teacherCount: (json['teacherCount'] as num?)?.toInt() ?? 0,
      studentCount: (json['studentCount'] as num?)?.toInt() ?? 0,
      classCount: (json['classCount'] as num?)?.toInt() ?? 0,
      subjectCount: (json['subjectCount'] as num?)?.toInt() ?? 0,
    );
  }
}