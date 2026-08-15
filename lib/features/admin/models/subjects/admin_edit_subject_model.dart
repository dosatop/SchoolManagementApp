class AdminEditSubjectModel {
  final String name;
  final String code;

  const AdminEditSubjectModel({
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