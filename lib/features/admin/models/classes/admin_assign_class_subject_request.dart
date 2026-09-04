class AdminAssignClassSubjectRequest {
  final String classId;
  final String subjectId;

  const AdminAssignClassSubjectRequest({
    required this.classId,
    required this.subjectId,
  });

  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'subjectId': subjectId,
    };
  }
}