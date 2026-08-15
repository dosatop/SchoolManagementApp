class AdminCreateClassModel {
  final String name;

  const AdminCreateClassModel({
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }
}