enum ResultStatus {
  draft,
  submitted,
  approved,
  rejected,
  published,
}

class ResultModel {
  final String id;

  // Student information
  final String studentId;
  final String studentName;

  // Academic information
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;
  final String session;
  final String term;

  // Teacher
  final String teacherId;
  final String teacherName;

  // Scores
  final double ca1;
  final double ca2;
  final double exam;

  // Result
  final double total;
  final String grade;

  // Status
  final ResultStatus status;

  const ResultModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.session,
    required this.term,
    required this.teacherId,
    required this.teacherName,
    required this.ca1,
    required this.ca2,
    required this.exam,
    required this.total,
    required this.grade,
    required this.status,
  });

  ResultModel copyWith({
    String? id,
    String? studentId,
    String? studentName,
    String? classId,
    String? className,
    String? subjectId,
    String? subjectName,
    String? session,
    String? term,
    String? teacherId,
    String? teacherName,
    double? ca1,
    double? ca2,
    double? exam,
    double? total,
    String? grade,
    ResultStatus? status,
  }) {
    return ResultModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      session: session ?? this.session,
      term: term ?? this.term,
      teacherId: teacherId ?? this.teacherId,
      teacherName: teacherName ?? this.teacherName,
      ca1: ca1 ?? this.ca1,
      ca2: ca2 ?? this.ca2,
      exam: exam ?? this.exam,
      total: total ?? this.total,
      grade: grade ?? this.grade,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'className': className,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'session': session,
      'term': term,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'ca1': ca1,
      'ca2': ca2,
      'exam': exam,
      'total': total,
      'grade': grade,
      'status': status.name,
    };
  }

  factory ResultModel.fromMap(Map<String, dynamic> map) {
    return ResultModel(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      classId: map['classId'] ?? '',
      className: map['className'] ?? '',
      subjectId: map['subjectId'] ?? '',
      subjectName: map['subjectName'] ?? '',
      session: map['session'] ?? '',
      term: map['term'] ?? '',
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      ca1: (map['ca1'] ?? 0).toDouble(),
      ca2: (map['ca2'] ?? 0).toDouble(),
      exam: (map['exam'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      grade: map['grade'] ?? '',
      status: ResultStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => ResultStatus.draft,
      ),
    );
  }
}