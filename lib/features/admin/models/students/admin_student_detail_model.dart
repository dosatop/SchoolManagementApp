import 'package:app/features/admin/models/attendance/admin_attendance_model.dart';
import 'package:app/features/admin/models/students/admin_student_parent_model.dart';

class AdminStudentDetailModel {
  final String studentId;
  final String studentNumber;
  final String schoolId;
  final String schoolName;
  final String studentName;
  final String email;
  final String? phoneNumber;
  final String classId;
  final String className;

  final List<AdminStudentParentModel> parents;
  final List<AdminStudentSubjectModel> subjects;
  final List<AdminStudentResultModel> results;
  final List<AdminStudentAttendanceModel> attendance;
  final List<AdminStudentAssignmentModel> assignments;

  const AdminStudentDetailModel({
    required this.studentId,
    required this.studentNumber,
    required this.schoolId,
    required this.schoolName,
    required this.studentName,
    required this.email,
    this.phoneNumber,
    required this.classId,
    required this.className,
    required this.parents,
    required this.subjects,
    required this.results,
    required this.attendance,
    required this.assignments,
  });

  factory AdminStudentDetailModel.fromJson(Map<String, dynamic> json) {
    return AdminStudentDetailModel(
      studentId: json['studentId']?.toString() ?? '',
      studentNumber: json['studentNumber']?.toString() ?? '',
      schoolId: json['schoolId']?.toString() ?? '',
      schoolName: json['schoolName']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      classId: json['classId']?.toString() ?? '',
      className: json['className']?.toString() ?? '',

      parents: (json['parents'] as List<dynamic>? ?? [])
          .map(
            (item) => AdminStudentParentModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),

      subjects: (json['subjects'] as List<dynamic>? ?? [])
          .map(
            (item) => AdminStudentSubjectModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),

      results: (json['results'] as List<dynamic>? ?? [])
          .map(
            (item) => AdminStudentResultModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),

      attendance: (json['attendance'] as List<dynamic>? ?? [])
          .map(
            (item) => AdminStudentAttendanceModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),

      assignments: (json['assignments'] as List<dynamic>? ?? [])
          .map(
            (item) => AdminStudentAssignmentModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

// ================================================================
// SUBJECT
// ================================================================

class AdminStudentSubjectModel {
  final String subjectId;
  final String subjectName;
  final String code;

  const AdminStudentSubjectModel({
    required this.subjectId,
    required this.subjectName,
    required this.code,
  });

  factory AdminStudentSubjectModel.fromJson(Map<String, dynamic> json) {
    return AdminStudentSubjectModel(
      subjectId: json['subjectId']?.toString() ?? '',
      subjectName: json['subjectName']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }
}

// ================================================================
// RESULT
// ================================================================

class AdminStudentResultModel {
  final String id;
  final String subjectId;
  final String subjectName;
  final double testScore;
  final double examScore;
  final double score;
  final String grade;
  final String remark;
  final String session;
  final String term;

  const AdminStudentResultModel({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.testScore,
    required this.examScore,
    required this.score,
    required this.grade,
    required this.remark,
    required this.session,
    required this.term,
  });

  factory AdminStudentResultModel.fromJson(Map<String, dynamic> json) {
    return AdminStudentResultModel(
      id: json['id']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      subjectName: json['subjectName']?.toString() ?? '',

      testScore: (json['testScore'] as num?)?.toDouble() ?? 0,

      examScore: (json['examScore'] as num?)?.toDouble() ?? 0,

      score: (json['score'] as num?)?.toDouble() ?? 0,

      grade: json['grade']?.toString() ?? '',
      remark: json['remark']?.toString() ?? '',
      session: json['session']?.toString() ?? '',
      term: json['term']?.toString() ?? '',
    );
  }
}

// ================================================================
// ATTENDANCE
// ================================================================
//
// Your current API response has:
//
// "attendance": []
//
// Since you haven't shown the attendance object structure yet,
// keep this flexible for now.

// ================================================================
// ASSIGNMENT
// ================================================================

class AdminStudentAssignmentModel {
  final String assignmentId;
  final String title;
  final String description;
  final String? attachmentUrl;

  final DateTime? assignedAt;
  final DateTime? dueDate;

  final String session;
  final String term;

  final String classId;
  final String className;

  final String subjectId;
  final String subjectName;

  final String teacherId;
  final String teacherName;

  final bool isPublished;

  final dynamic submission;

  const AdminStudentAssignmentModel({
    required this.assignmentId,
    required this.title,
    required this.description,
    this.attachmentUrl,
    this.assignedAt,
    this.dueDate,
    required this.session,
    required this.term,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
    required this.isPublished,
    this.submission,
  });

  factory AdminStudentAssignmentModel.fromJson(Map<String, dynamic> json) {
    return AdminStudentAssignmentModel(
      assignmentId: json['assignmentId']?.toString() ?? '',

      title: json['title']?.toString() ?? '',

      description: json['description']?.toString() ?? '',

      attachmentUrl: json['attachmentUrl']?.toString(),

      assignedAt: DateTime.tryParse(json['assignedAt']?.toString() ?? ''),

      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? ''),

      session: json['session']?.toString() ?? '',

      term: json['term']?.toString() ?? '',

      classId: json['classId']?.toString() ?? '',

      className: json['className']?.toString() ?? '',

      subjectId: json['subjectId']?.toString() ?? '',

      subjectName: json['subjectName']?.toString() ?? '',

      teacherId: json['teacherId']?.toString() ?? '',

      teacherName: json['teacherName']?.toString() ?? '',

      isPublished: json['isPublished'] == true,

      submission: json['submission'],
    );
  }
}
