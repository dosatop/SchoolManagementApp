// ====================================================================
// SUPER ADMIN — SCHOOL TEACHERS / STUDENTS / CLASSES MODELS
// ====================================================================
// Tolerant: camelCase or PascalCase keys, missing fields default,
// bad list items are skipped instead of failing the whole page.

dynamic _pick(dynamic json, List<String> keys) {
  if (json is! Map) return null;
  for (final key in keys) {
    if (json.containsKey(key) && json[key] != null) return json[key];
    final pascal = key.isEmpty ? key : key[0].toUpperCase() + key.substring(1);
    if (json.containsKey(pascal) && json[pascal] != null) return json[pascal];
  }
  return null;
}

String _str(dynamic json, List<String> keys, [String fallback = '']) {
  final v = _pick(json, keys);
  if (v == null) return fallback;
  final s = v.toString().trim();
  return s.isEmpty ? fallback : s;
}

String? _strOrNull(dynamic json, List<String> keys) {
  final s = _str(json, keys);
  return s.isEmpty ? null : s;
}

int _int(dynamic json, List<String> keys) {
  final v = _pick(json, keys);
  if (v is num) return v.toInt();
  return int.tryParse('${v ?? ''}') ?? 0;
}

bool? _bool(dynamic json, List<String> keys) {
  final v = _pick(json, keys);
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true';
  return null;
}

List<T> _list<T>(dynamic json, List<String> keys, T Function(dynamic) map) {
  final v = _pick(json, keys);
  if (v is! List) return <T>[];
  final out = <T>[];
  for (final item in v) {
    try {
      out.add(map(item));
    } catch (_) {
      // Skip a bad row.
    }
  }
  return out;
}

/// Accepts a plain list, or an object wrapping one under [key]
/// (e.g. `{ teachers: [...] }`, `{ data: [...] }`).
List<dynamic> unwrapList(dynamic data, String key) {
  if (data is List) return data;
  if (data is Map) {
    final v = _pick(data, [key, 'items', 'data', 'result']);
    if (v is List) return v;
    if (v is Map) return unwrapList(v, key);
  }
  return const [];
}

List<T> parseList<T>(dynamic data, String key, T Function(dynamic) map) {
  final out = <T>[];
  for (final item in unwrapList(data, key)) {
    try {
      out.add(map(item));
    } catch (_) {}
  }
  return out;
}

// ====================================================================
// SMALL REFERENCES
// ====================================================================

class SchoolClassRef {
  final String classId;
  final String className;

  const SchoolClassRef({required this.classId, required this.className});

  factory SchoolClassRef.fromJson(dynamic json) => SchoolClassRef(
    classId: _str(json, ['classId', 'id']),
    className: _str(json, ['className', 'name'], 'Class'),
  );
}

class SchoolTeacherSubject {
  final String subjectId;
  final String subjectName;
  final String classId;
  final String className;

  const SchoolTeacherSubject({
    required this.subjectId,
    required this.subjectName,
    required this.classId,
    required this.className,
  });

  factory SchoolTeacherSubject.fromJson(dynamic json) => SchoolTeacherSubject(
    subjectId: _str(json, ['subjectId', 'id']),
    subjectName: _str(json, ['subjectName', 'name'], 'Subject'),
    classId: _str(json, ['classId']),
    className: _str(json, ['className'], 'Class'),
  );
}

class SchoolSubjectTeacher {
  final String subjectId;
  final String subjectName;
  final String teacherId;
  final String teacherName;

  const SchoolSubjectTeacher({
    required this.subjectId,
    required this.subjectName,
    required this.teacherId,
    required this.teacherName,
  });

  factory SchoolSubjectTeacher.fromJson(dynamic json) => SchoolSubjectTeacher(
    subjectId: _str(json, ['subjectId']),
    subjectName: _str(json, ['subjectName', 'name'], 'Subject'),
    teacherId: _str(json, ['teacherId']),
    teacherName: _str(json, ['teacherName', 'fullName'], 'Teacher'),
  );
}

class SchoolTeacherRef {
  final String teacherId;
  final String teacherName;

  const SchoolTeacherRef({required this.teacherId, required this.teacherName});

  factory SchoolTeacherRef.fromJson(dynamic json) => SchoolTeacherRef(
    teacherId: _str(json, ['teacherId', 'id']),
    teacherName: _str(json, ['teacherName', 'fullName', 'name'], 'Teacher'),
  );
}

// ====================================================================
// TEACHER
// ====================================================================

class SchoolTeacher {
  final String id;
  final String fullName;
  final String? email;
  final String? phoneNumber;
  final List<SchoolClassRef> classTeacherOf;
  final List<SchoolTeacherSubject> subjects;
  final int subjectCount;
  final int classCount;

  const SchoolTeacher({
    required this.id,
    required this.fullName,
    this.email,
    this.phoneNumber,
    this.classTeacherOf = const [],
    this.subjects = const [],
    this.subjectCount = 0,
    this.classCount = 0,
  });

  bool get isClassTeacher => classTeacherOf.isNotEmpty;

  /// Distinct subject names, e.g. "Mathematics, Physics".
  List<String> get subjectNames {
    final seen = <String>{};
    return subjects.map((s) => s.subjectName).where(seen.add).toList();
  }

  factory SchoolTeacher.fromJson(dynamic json) {
    final classTeacherOf = _list(
      json,
      ['classTeacherOf', 'classes'],
      SchoolClassRef.fromJson,
    );
    final subjects = _list(json, ['subjects'], SchoolTeacherSubject.fromJson);

    final subjectCount = _int(json, ['subjectCount']);
    final classCount = _int(json, ['classCount']);

    return SchoolTeacher(
      id: _str(json, ['teacherId', 'id']),
      fullName: _str(json, ['fullName', 'teacherName', 'name'], 'Teacher'),
      email: _strOrNull(json, ['email']),
      phoneNumber: _strOrNull(json, ['phoneNumber', 'phone']),
      classTeacherOf: classTeacherOf,
      subjects: subjects,
      subjectCount: subjectCount > 0
          ? subjectCount
          : subjects.map((s) => s.subjectId).toSet().length,
      classCount: classCount > 0
          ? classCount
          : {
              ...subjects.map((s) => s.classId),
              ...classTeacherOf.map((c) => c.classId),
            }.length,
    );
  }
}

// ====================================================================
// STUDENT
// ====================================================================

class SchoolStudent {
  final String id;
  final String fullName;
  final String? studentNumber;
  final String? email;
  final String? phoneNumber;
  final String? classId;
  final String? className;
  final String? departmentName;
  final String? tradeName;

  const SchoolStudent({
    required this.id,
    required this.fullName,
    this.studentNumber,
    this.email,
    this.phoneNumber,
    this.classId,
    this.className,
    this.departmentName,
    this.tradeName,
  });

  bool get hasClass =>
      classId != null &&
      classId!.isNotEmpty &&
      classId != '00000000-0000-0000-0000-000000000000';

  factory SchoolStudent.fromJson(dynamic json) => SchoolStudent(
    id: _str(json, ['studentId', 'id']),
    fullName: _str(json, ['fullName', 'studentName', 'name'], 'Student'),
    studentNumber: _strOrNull(json, ['studentNumber', 'admissionNumber']),
    email: _strOrNull(json, ['email']),
    phoneNumber: _strOrNull(json, ['phoneNumber', 'phone']),
    classId: _strOrNull(json, ['classId']),
    className: _strOrNull(json, ['className']),
    departmentName: _strOrNull(json, ['departmentName', 'department']),
    tradeName: _strOrNull(json, ['tradeName', 'trade']),
  );
}

// ====================================================================
// CLASS
// ====================================================================

class SchoolClass {
  final String id;
  final String name;
  final String? levelName;
  final int studentCount;
  final int subjectCount;
  final List<SchoolTeacherRef> classTeachers;
  final List<SchoolSubjectTeacher> subjectTeachers;

  const SchoolClass({
    required this.id,
    required this.name,
    this.levelName,
    this.studentCount = 0,
    this.subjectCount = 0,
    this.classTeachers = const [],
    this.subjectTeachers = const [],
  });

  bool get hasClassTeacher => classTeachers.isNotEmpty;

  String get classTeacherLabel => classTeachers.isEmpty
      ? 'No class teacher'
      : classTeachers.map((t) => t.teacherName).join(', ');

  factory SchoolClass.fromJson(dynamic json) {
    final classTeachers = _list(
      json,
      ['classTeachers'],
      SchoolTeacherRef.fromJson,
    );

    // Older shapes: a single classTeacherName field.
    final singleName = _strOrNull(json, ['classTeacherName', 'teacherName']);
    if (classTeachers.isEmpty && singleName != null) {
      classTeachers.add(
        SchoolTeacherRef(
          teacherId: _str(json, ['classTeacherId', 'teacherId']),
          teacherName: singleName,
        ),
      );
    }

    final hasTeacherFlag = _bool(json, ['hasClassTeacher']);
    if (hasTeacherFlag == false) classTeachers.clear();

    return SchoolClass(
      id: _str(json, ['classId', 'id']),
      name: _str(json, ['className', 'name'], 'Class'),
      levelName: _strOrNull(json, ['levelName', 'schoolLevel']),
      studentCount: _int(json, ['studentCount', 'studentsCount']),
      subjectCount: _int(json, ['subjectCount', 'subjectsCount']),
      classTeachers: classTeachers,
      subjectTeachers: _list(
        json,
        ['subjectTeachers'],
        SchoolSubjectTeacher.fromJson,
      ),
    );
  }
}
