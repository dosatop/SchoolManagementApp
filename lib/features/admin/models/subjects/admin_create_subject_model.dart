class AdminCreateSubjectModel {
  final String name;
  final String code;

  const AdminCreateSubjectModel({
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