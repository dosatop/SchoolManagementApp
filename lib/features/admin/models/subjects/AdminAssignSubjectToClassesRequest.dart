class AdminAssignSubjectToClassesRequest {
  final List<String> classIds;
  final String? teacherId;

  AdminAssignSubjectToClassesRequest({
    required this.classIds,
    this.teacherId,
  });

  Map<String, dynamic> toJson() {
    return {
      'classIds': classIds,
      'teacherId': teacherId,
    };
  }
}