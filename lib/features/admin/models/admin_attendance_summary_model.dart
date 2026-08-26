class AdminStudentAttendanceSummaryModel {
  final int totalRecords;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final int holiday;
  final int attendanceDays;
  final double attendancePercentage;

  const AdminStudentAttendanceSummaryModel({
    required this.totalRecords,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.holiday,
    required this.attendanceDays,
    required this.attendancePercentage,
  });

  factory AdminStudentAttendanceSummaryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminStudentAttendanceSummaryModel(
      totalRecords: json['totalRecords'] ?? 0,
      present: json['present'] ?? 0,
      absent: json['absent'] ?? 0,
      late: json['late'] ?? 0,
      excused: json['excused'] ?? 0,
      holiday: json['holiday'] ?? 0,
      attendanceDays: json['attendanceDays'] ?? 0,
      attendancePercentage:
          (json['attendancePercentage'] as num?)?.toDouble() ?? 0,
    );
  }
}