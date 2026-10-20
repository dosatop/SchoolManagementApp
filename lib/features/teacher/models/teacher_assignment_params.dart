class TeacherAssignmentsParams {
  final String classId;
  final String subjectId;
  final String? session;
  final String? term;

  const TeacherAssignmentsParams({
    required this.classId,
    required this.subjectId,
    this.session,
    this.term,
  });

  TeacherAssignmentsParams copyWith({
    String? classId,
    String? subjectId,
    String? session,
    String? term,
  }) {
    return TeacherAssignmentsParams(
      classId: classId ?? this.classId,
      subjectId: subjectId ?? this.subjectId,
      session: session ?? this.session,
      term: term ?? this.term,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TeacherAssignmentsParams &&
        other.classId == classId &&
        other.subjectId == subjectId &&
        other.session == session &&
        other.term == term;
  }

  @override
  int get hashCode {
    return Object.hash(
      classId,
      subjectId,
      session,
      term,
    );
  }

  @override
  String toString() {
    return 'TeacherAssignmentsParams('
        'classId: $classId, '
        'subjectId: $subjectId, '
        'session: $session, '
        'term: $term'
        ')';
  }
}