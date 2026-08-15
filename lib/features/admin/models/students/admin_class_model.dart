class AdminClassModel {
  final String classId;
  final String className;
  final String schoolId;
  final List<AdminClassStudentModel> students;
  final List<AdminClassTeacherModel> teachers;

  const AdminClassModel({
    required this.classId,
    required this.className,
    required this.schoolId,
    required this.students,
    required this.teachers,
  });

  factory AdminClassModel.fromJson(Map<String, dynamic> json) {
    return AdminClassModel(
      classId: json['classId'] ?? '',
      className: json['className'] ?? '',
      schoolId: json['schoolId'] ?? '',
      students: (json['students'] as List? ?? [])
          .map(
            (student) => AdminClassStudentModel.fromJson(
              Map<String, dynamic>.from(student),
            ),
          )
          .toList(),
      teachers: (json['teachers'] as List? ?? [])
          .map(
            (teacher) => AdminClassTeacherModel.fromJson(
              Map<String, dynamic>.from(teacher),
            ),
          )
          .toList(),
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

  const AdminClassStudentModel({
    required this.studentId,
    required this.studentNumber,
    required this.studentName,
    required this.email,
    this.phoneNumber,
  });

  factory AdminClassStudentModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminClassStudentModel(
      studentId: json['studentId'] ?? '',
      studentNumber: json['studentNumber'] ?? '',
      studentName: json['studentName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
    );
  }
}

// ==================================================================
// TEACHER
// ==================================================================

class AdminClassTeacherModel {
  final String teacherId;
  final String teacherName;
  final String email;
  final String? phoneNumber;

  const AdminClassTeacherModel({
    required this.teacherId,
    required this.teacherName,
    required this.email,
    this.phoneNumber,
  });

  factory AdminClassTeacherModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminClassTeacherModel(
      teacherId: json['teacherId'] ?? '',
      teacherName: json['teacherName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
    );
  }
}