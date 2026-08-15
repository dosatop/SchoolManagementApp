class ClassModel {
  final String id;
  final String name;
  final String? description;

  ClassModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'],
    );
  }
}