// ==================================================================
// STUDENT ATTENDANCE RESPONSE
// ==================================================================

class AdminStudentAttendanceModel {
  final String studentId;
  final String studentNumber;
  final String studentName;
  final String schoolId;
  final String classId;
  final String className;
  final String session;
  final String term;
  final AdminAttendanceSummaryModel summary;
  final List<AdminAttendanceRecordModel> records;

  const AdminStudentAttendanceModel({
    required this.studentId,
    required this.studentNumber,
    required this.studentName,
    required this.schoolId,
    required this.classId,
    required this.className,
    required this.session,
    required this.term,
    required this.summary,
    required this.records,
  });

  factory AdminStudentAttendanceModel.fromJson(Map<String, dynamic> json) {
    return AdminStudentAttendanceModel(
      studentId: json['studentId'] as String? ?? '',
      studentNumber: json['studentNumber'] as String? ?? '',
      studentName: json['studentName'] as String? ?? '',
      schoolId: json['schoolId'] as String? ?? '',
      classId: json['classId'] as String? ?? '',
      className: json['className'] as String? ?? '',
      session: json['session'] as String? ?? '',
      term: json['term'] as String? ?? '',
      summary: AdminAttendanceSummaryModel.fromJson(
        Map<String, dynamic>.from(json['summary'] as Map? ?? {}),
      ),
      records: (json['records'] as List? ?? [])
          .map(
            (record) => AdminAttendanceRecordModel.fromJson(
              Map<String, dynamic>.from(record),
            ),
          )
          .toList(),
    );
  }
}

// ==================================================================
// ATTENDANCE SUMMARY
// ==================================================================

class AdminAttendanceSummaryModel {
  final int totalRecords;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final int holiday;
  final int attendanceDays;
  final double attendancePercentage;

  const AdminAttendanceSummaryModel({
    required this.totalRecords,
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.holiday,
    required this.attendanceDays,
    required this.attendancePercentage,
  });

  factory AdminAttendanceSummaryModel.fromJson(Map<String, dynamic> json) {
    return AdminAttendanceSummaryModel(
      totalRecords: _toInt(json['totalRecords']),
      present: _toInt(json['present']),
      absent: _toInt(json['absent']),
      late: _toInt(json['late']),
      excused: _toInt(json['excused']),
      holiday: _toInt(json['holiday']),
      attendanceDays: _toInt(json['attendanceDays']),
      attendancePercentage: _toDouble(json['attendancePercentage']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

// ==================================================================
// ATTENDANCE RECORD
// ==================================================================

class AdminAttendanceRecordModel {
  final String id;
  final String attendanceDate;
  final String status;
  final String? remarks;
  final String? subjectId;
  final String? subjectName;
  final String? teacherId;
  final String? classId;
  final String? schoolId;
  final String? session;
  final String? term;

  const AdminAttendanceRecordModel({
    required this.id,
    required this.attendanceDate,
    required this.status,
    required this.remarks,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.classId,
    required this.schoolId,
    required this.session,
    required this.term,
  });

  factory AdminAttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AdminAttendanceRecordModel(
      id: json['id'] as String? ?? '',
      attendanceDate: json['attendanceDate'] as String? ?? '',
      status: json['status'] as String? ?? '',
      remarks: json['remarks'] as String?,
      subjectId: json['subjectId'] as String?,
      subjectName: json['subjectName'] as String?,
      teacherId: json['teacherId'] as String?,
      classId: json['classId'] as String?,
      schoolId: json['schoolId'] as String?,
      session: json['session'] as String?,
      term: json['term'] as String?,
    );
  }
}

class AdminStudentAttendanceParams {
  final String studentId;
  final String session;
  final String term;

  const AdminStudentAttendanceParams({
    required this.studentId,
    required this.session,
    required this.term,
  });

  @override
  bool operator ==(Object other) {
    return other is AdminStudentAttendanceParams &&
        other.studentId == studentId &&
        other.session == session &&
        other.term == term;
  }

  @override
  int get hashCode {
    return Object.hash(studentId, session, term);
  }
}
