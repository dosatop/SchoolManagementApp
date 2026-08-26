// ==================================================================
// CLASS
// ==================================================================

class AdminClassModel {
  final String classId;
  final String className;
  final String schoolId;

  final String? classTeacherId;
  final String? classTeacherName;

  final List<AdminClassSubjectModel> subjects;
  final List<AdminClassStudentModel> students;
  final List<AdminClassTeacherModel> teachers;

  const AdminClassModel({
    required this.classId,
    required this.className,
    required this.schoolId,
    required this.classTeacherId,
    required this.classTeacherName,
    required this.subjects,
    required this.students,
    required this.teachers,
  });

  factory AdminClassModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminClassModel(
      classId: json['classId'] as String? ?? '',
      className: json['className'] as String? ?? '',
      schoolId: json['schoolId'] as String? ?? '',

      classTeacherId:
          json['classTeacherId'] as String?,

      classTeacherName:
          json['classTeacherName'] as String?,

      // ============================================================
      // SUBJECTS
      // ============================================================

      subjects: (json['subjects'] as List? ?? [])
          .map(
            (subject) =>
                AdminClassSubjectModel.fromJson(
              Map<String, dynamic>.from(subject),
            ),
          )
          .toList(),

      // ============================================================
      // STUDENTS
      // ============================================================

      students: (json['students'] as List? ?? [])
          .map(
            (student) =>
                AdminClassStudentModel.fromJson(
              Map<String, dynamic>.from(student),
            ),
          )
          .toList(),

      // ============================================================
      // TEACHERS
      // ============================================================

      teachers: (json['teachers'] as List? ?? [])
          .map(
            (teacher) =>
                AdminClassTeacherModel.fromJson(
              Map<String, dynamic>.from(teacher),
            ),
          )
          .toList(),
    );
  }
}

// ==================================================================
// SUBJECT
// ==================================================================

class AdminClassSubjectModel {
  final String subjectId;
  final String subjectName;
  final String subjectCode;

  const AdminClassSubjectModel({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
  });

  factory AdminClassSubjectModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminClassSubjectModel(
      subjectId:
          json['subjectId'] as String? ?? '',

      subjectName:
          json['subjectName'] as String? ?? '',

      subjectCode:
          json['subjectCode'] as String? ?? '',
    );
  }
}

// ==================================================================
// STUDENT
// ==================================================================

class AdminClassStudentModel {
  final String studentId;
  final String studentNumber;
  final String studentName;
  final String email;
  final String? phoneNumber;

  final int parentCount;

  final List<AdminClassStudentResultModel> results;

  final List<AdminClassStudentAttendanceModel> attendance;

  const AdminClassStudentModel({
    required this.studentId,
    required this.studentNumber,
    required this.studentName,
    required this.email,
    required this.phoneNumber,
    required this.parentCount,
    required this.results,
    required this.attendance,
  });

  factory AdminClassStudentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminClassStudentModel(
      studentId:
          json['studentId'] as String? ?? '',

      studentNumber:
          json['studentNumber'] as String? ?? '',

      studentName:
          json['studentName'] as String? ?? '',

      email:
          json['email'] as String? ?? '',

      phoneNumber:
          json['phoneNumber'] as String?,

      parentCount:
          (json['parentCount'] as num?)?.toInt() ?? 0,

      // ============================================================
      // RESULTS
      // ============================================================

      results: (json['results'] as List? ?? [])
          .map(
            (result) =>
                AdminClassStudentResultModel.fromJson(
              Map<String, dynamic>.from(result),
            ),
          )
          .toList(),

      // ============================================================
      // ATTENDANCE
      // ============================================================

      attendance: (json['attendance'] as List? ?? [])
          .map(
            (item) =>
                AdminClassStudentAttendanceModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }
}

// ==================================================================
// STUDENT RESULT
// ==================================================================
//
// Your current API example returns:
// "results": []
//
// Since no result object was provided, this model is intentionally
// flexible for now. Add the actual result fields when the API returns
// them.
// ==================================================================

class AdminClassStudentResultModel {
  final Map<String, dynamic> data;

  const AdminClassStudentResultModel({
    required this.data,
  });

  factory AdminClassStudentResultModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminClassStudentResultModel(
      data: json,
    );
  }
}

// ==================================================================
// STUDENT ATTENDANCE
// ==================================================================

class AdminClassStudentAttendanceModel {
  final String attendanceId;

  final String subjectId;
  final String subjectName;
  final String subjectCode;

  final String teacherId;
  final String teacherName;

  final String attendanceDate;

  final int status;

  final String session;
  final String term;

  const AdminClassStudentAttendanceModel({
    required this.attendanceId,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.teacherId,
    required this.teacherName,
    required this.attendanceDate,
    required this.status,
    required this.session,
    required this.term,
  });

  factory AdminClassStudentAttendanceModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminClassStudentAttendanceModel(
      attendanceId:
          json['attendanceId'] as String? ?? '',

      subjectId:
          json['subjectId'] as String? ?? '',

      subjectName:
          json['subjectName'] as String? ?? '',

      subjectCode:
          json['subjectCode'] as String? ?? '',

      teacherId:
          json['teacherId'] as String? ?? '',

      teacherName:
          json['teacherName'] as String? ?? '',

      attendanceDate:
          json['attendanceDate'] as String? ?? '',

      status:
          (json['status'] as num?)?.toInt() ?? 0,

      session:
          json['session'] as String? ?? '',

      term:
          json['term'] as String? ?? '',
    );
  }

  bool get isPresent => status == 1;

  bool get isAbsent => status == 0;
}

// ==================================================================
// TEACHER
// ==================================================================

class AdminClassTeacherModel {
  final String teacherId;
  final String teacherName;

  final String? email;
  final String? phoneNumber;

  final String? subjectId;
  final String? classId;
  final String? className;

  final String? subjectName;
  final String? subjectCode;

  const AdminClassTeacherModel({
    required this.teacherId,
    required this.teacherName,
    required this.email,
    required this.phoneNumber,
    required this.subjectId,
    required this.classId,
    required this.className,
    required this.subjectName,
    required this.subjectCode,
  });

  factory AdminClassTeacherModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminClassTeacherModel(
      teacherId:
          json['teacherId'] as String? ?? '',

      teacherName:
          json['teacherName'] as String? ?? '',

      email:
          json['email'] as String?,

      phoneNumber:
          json['phoneNumber'] as String?,

      subjectId:
          json['subjectId'] as String?,

      classId:
          json['classId'] as String?,

      className:
          json['className'] as String?,

      subjectName:
          json['subjectName'] as String?,

      subjectCode:
          json['subjectCode'] as String?,
    );
  }
}