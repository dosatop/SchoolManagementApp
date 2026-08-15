class SubjectModel {
  final String id;
  final String name;
  final String? code;
  final String? description;
  final String? schoolId;

  SubjectModel({
    required this.id,
    required this.name,
    this.code,
    this.description,
    this.schoolId,
  });

  factory SubjectModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SubjectModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      description: json['description']?.toString(),
      schoolId: json['schoolId']?.toString(),
    );
  }
}