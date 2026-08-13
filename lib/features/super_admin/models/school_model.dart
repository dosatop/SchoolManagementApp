class SchoolModel {
  final String id;
  final String name;
  final String address;
  final String? phoneNumber;
  final String? email;
  final DateTime? createdAt;

  final List<dynamic> users;
  final List<dynamic> classes;
  final List<dynamic> subjects;

  const SchoolModel({
    required this.id,
    required this.name,
    required this.address,
    this.phoneNumber,
    this.email,
    this.createdAt,
    this.users = const [],
    this.classes = const [],
    this.subjects = const [],
  });

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
      email: json['email']?.toString(),

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(
              json['createdAt'].toString(),
            )
          : null,

      users: json['users'] is List
          ? List<dynamic>.from(json['users'])
          : const [],

      classes: json['classes'] is List
          ? List<dynamic>.from(json['classes'])
          : const [],

      subjects: json['subjects'] is List
          ? List<dynamic>.from(json['subjects'])
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      'email': email,
      'createdAt': createdAt?.toIso8601String(),
      'users': users,
      'classes': classes,
      'subjects': subjects,
    };
  }
}