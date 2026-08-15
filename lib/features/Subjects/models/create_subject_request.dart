class CreateSubjectRequest {
  final String name;
  final String code;

  CreateSubjectRequest({
    required this.name,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
    };
  }
}