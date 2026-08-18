class AdminParentModel {
  final String parentId;
  final String userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final int childrenCount;

  const AdminParentModel({
    required this.parentId,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.childrenCount,
  });

  factory AdminParentModel.fromJson(Map<String, dynamic> json) {
    return AdminParentModel(
      parentId: json['parentId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      childrenCount: json['childrenCount'] is int
          ? json['childrenCount'] as int
          : int.tryParse(json['childrenCount']?.toString() ?? '0') ?? 0,
    );
  }

  AdminParentModel copyWith({
    String? parentId,
    String? userId,
    String? fullName,
    String? email,
    String? phoneNumber,
    int? childrenCount,
  }) {
    return AdminParentModel(
      parentId: parentId ?? this.parentId,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      childrenCount: childrenCount ?? this.childrenCount,
    );
  }
}