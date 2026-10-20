class TeacherClassAttendanceParams {
  final String classId;
  final String? subjectId;
  final String? date;
  final String? session;
  final String? term;

  const TeacherClassAttendanceParams({
    required this.classId,
    this.subjectId,
    this.date,
    this.session,
    this.term,
  });

  @override
  bool operator ==(Object other) {
    return other is TeacherClassAttendanceParams &&
        other.classId == classId &&
        other.subjectId == subjectId &&
        other.date == date &&
        other.session == session &&
        other.term == term;
  }

  @override
  int get hashCode {
    return Object.hash(
      classId,
      subjectId,
      date,
      session,
      term,
    );
  }
}
