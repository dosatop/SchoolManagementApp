import 'package:app/features/admin/models/students/admin_student_parent_model.dart';

// ==================================================================
// ADMIN STUDENT DETAIL  (GET /admin/students/{id}/records)
// ==================================================================
// Tolerant parsing:
//   • numbers may arrive as int, double or string  → always double
//   • strings may be null                          → '' or null
//   • keys may be camelCase or PascalCase
//   • one broken list item is skipped, not fatal
// ==================================================================

class AdminStudentDetailModel {
  final String studentId;
  final String studentNumber;
  final String studentName;
  final String email;
  final String? phoneNumber;

  final String schoolId;
  final String schoolName;

  final String classId;
  final String className;
  final String schoolLevel;

  final String? departmentId;
  final String? departmentName;

  final String? tradeId;
  final String? tradeName;

  final String? tradeSubjectId;
  final String? tradeSubjectName;
  final String? tradeSubjectCode;

  final List<AdminStudentParentModel> parents;
  final List<AdminStudentSubjectModel> subjects;
  final List<AdminStudentResultModel> results;
  final List<AdminStudentAssignmentModel> assignments;

  const AdminStudentDetailModel({
    required this.studentId,
    required this.studentNumber,
    required this.studentName,
    required this.email,
    this.phoneNumber,
    required this.schoolId,
    required this.schoolName,
    required this.classId,
    required this.className,
    required this.schoolLevel,
    this.departmentId,
    this.departmentName,
    this.tradeId,
    this.tradeName,
    this.tradeSubjectId,
    this.tradeSubjectName,
    this.tradeSubjectCode,
    this.parents = const [],
    this.subjects = const [],
    this.results = const [],
    this.assignments = const [],
  });

  factory AdminStudentDetailModel.fromJson(Map<String, dynamic> raw) {
    // Some endpoints wrap the payload in { data: {...} }.
    final json = raw['data'] is Map && raw['studentId'] == null
        ? Map<String, dynamic>.from(raw['data'] as Map)
        : raw;

    return AdminStudentDetailModel(
      studentId: _str(json, ['studentId', 'id']),
      studentNumber: _str(json, ['studentNumber']),
      studentName: _str(json, ['studentName', 'fullName', 'name']),
      email: _str(json, ['email']),
      phoneNumber: _strOrNull(json, ['phoneNumber', 'phone']),
      schoolId: _str(json, ['schoolId']),
      schoolName: _str(json, ['schoolName']),
      classId: _str(json, ['classId']),
      className: _str(json, ['className']),
      schoolLevel: _str(json, ['schoolLevel']),
      departmentId: _strOrNull(json, ['departmentId']),
      departmentName: _strOrNull(json, ['departmentName']),
      tradeId: _strOrNull(json, ['tradeId']),
      tradeName: _strOrNull(json, ['tradeName']),
      tradeSubjectId: _strOrNull(json, ['tradeSubjectId']),
      tradeSubjectName: _strOrNull(json, ['tradeSubjectName']),
      tradeSubjectCode: _strOrNull(json, ['tradeSubjectCode']),
      parents: _list(json, ['parents'], AdminStudentParentModel.fromJson),
      subjects: _list(json, ['subjects'], AdminStudentSubjectModel.fromJson),
      results: _list(json, ['results'], AdminStudentResultModel.fromJson),
      assignments: _list(json, [
        'assignments',
      ], AdminStudentAssignmentModel.fromJson),
    );
  }
}

// ==================================================================
// SUBJECT
// ==================================================================

class AdminStudentSubjectModel {
  final String subjectId;
  final String subjectName;
  final String code;
  final String? subjectType;

  const AdminStudentSubjectModel({
    required this.subjectId,
    required this.subjectName,
    required this.code,
    this.subjectType,
  });

  factory AdminStudentSubjectModel.fromJson(Map<String, dynamic> json) {
    return AdminStudentSubjectModel(
      subjectId: _str(json, ['subjectId', 'id']),
      subjectName: _str(json, ['subjectName', 'name']),
      code: _str(json, ['code', 'subjectCode']),
      subjectType: _strOrNull(json, ['subjectType', 'type']),
    );
  }
}

// ==================================================================
// RESULT
// ==================================================================

class AdminStudentResultModel {
  final String id;
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String classId;
  final String className;
  final String session;
  final String term;
  final double testScore;
  final double examScore;
  final double score;
  final String grade;
  final String? gradeRemark;
  final String? remark;
  final DateTime? createdAt;

  const AdminStudentResultModel({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.classId,
    required this.className,
    required this.session,
    required this.term,
    required this.testScore,
    required this.examScore,
    required this.score,
    required this.grade,
    this.gradeRemark,
    this.remark,
    this.createdAt,
  });

  factory AdminStudentResultModel.fromJson(Map<String, dynamic> json) {
    return AdminStudentResultModel(
      id: _str(json, ['id', 'resultId']),
      subjectId: _str(json, ['subjectId']),
      subjectName: _str(json, ['subjectName']),
      subjectCode: _str(json, ['subjectCode', 'code']),
      classId: _str(json, ['classId']),
      className: _str(json, ['className']),
      session: _str(json, ['session']),
      term: _str(json, ['term']),
      testScore: _double(json, ['testScore']),
      examScore: _double(json, ['examScore']),
      score: _double(json, ['score', 'totalScore', 'total']),
      grade: _str(json, ['grade']),
      gradeRemark: _strOrNull(json, ['gradeRemark']),
      remark: _strOrNull(json, ['remark']),
      createdAt: _date(json, ['createdAt']),
    );
  }
}

// ==================================================================
// ASSIGNMENT
// ==================================================================

class AdminStudentAssignmentModel {
  final String id;
  final String title;
  final String description;
  final String subjectId;
  final String subjectName;
  final String teacherName;
  final String session;
  final String term;
  final String? attachmentUrl;
  final DateTime? assignedAt;
  final DateTime? dueDate;
  final bool isPublished;

  // This student's submission
  final bool isSubmitted;
  final DateTime? submittedAt;
  final bool isGraded;
  final double? submissionScore;

  const AdminStudentAssignmentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.subjectId,
    required this.subjectName,
    required this.teacherName,
    required this.session,
    required this.term,
    this.attachmentUrl,
    this.assignedAt,
    this.dueDate,
    this.isPublished = true,
    this.isSubmitted = false,
    this.submittedAt,
    this.isGraded = false,
    this.submissionScore,
  });

  factory AdminStudentAssignmentModel.fromJson(Map<String, dynamic> json) {
    return AdminStudentAssignmentModel(
      id: _str(json, ['id', 'assignmentId']),
      title: _str(json, ['title']),
      description: _str(json, ['description']),
      subjectId: _str(json, ['subjectId']),
      subjectName: _str(json, ['subjectName']),
      teacherName: _str(json, ['teacherName']),
      session: _str(json, ['session']),
      term: _str(json, ['term']),
      attachmentUrl: _strOrNull(json, ['attachmentUrl']),
      assignedAt: _date(json, ['assignedAt']),
      dueDate: _date(json, ['dueDate']),
      isPublished: _bool(json, ['isPublished'], fallback: true),
      isSubmitted: _bool(json, ['isSubmitted']),
      submittedAt: _date(json, ['submittedAt']),
      isGraded: _bool(json, ['isGraded']),
      submissionScore: _doubleOrNull(json, ['submissionScore']),
    );
  }
}

// ==================================================================
// HELPERS
// ==================================================================

/// Finds the first key present, trying camelCase and PascalCase.
dynamic _pick(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) return json[key];
    final pascal = key[0].toUpperCase() + key.substring(1);
    if (json.containsKey(pascal) && json[pascal] != null) return json[pascal];
  }
  return null;
}

String _str(Map<String, dynamic> json, List<String> keys) =>
    _pick(json, keys)?.toString().trim() ?? '';

String? _strOrNull(Map<String, dynamic> json, List<String> keys) {
  final s = _pick(json, keys)?.toString().trim();
  return s == null || s.isEmpty ? null : s;
}

double? _doubleOrNull(Map<String, dynamic> json, List<String> keys) {
  final v = _pick(json, keys);
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim());
  return null;
}

double _double(Map<String, dynamic> json, List<String> keys) =>
    _doubleOrNull(json, keys) ?? 0;

bool _bool(
  Map<String, dynamic> json,
  List<String> keys, {
  bool fallback = false,
}) {
  final v = _pick(json, keys);
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.trim().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return fallback;
}

DateTime? _date(Map<String, dynamic> json, List<String> keys) {
  final v = _pick(json, keys);
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

/// Parses a list; a single bad item is skipped instead of failing the page.
List<T> _list<T>(
  Map<String, dynamic> json,
  List<String> keys,
  T Function(Map<String, dynamic>) parse,
) {
  final v = _pick(json, keys);
  if (v is! List) return const [];

  final out = <T>[];
  for (final item in v) {
    if (item is! Map) continue;
    try {
      out.add(parse(Map<String, dynamic>.from(item)));
    } catch (_) {
      // Skip the broken row.
    }
  }
  return out;
}
