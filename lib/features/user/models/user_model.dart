
class UserModel {
  final String email;
  final double fullName;
  final String phoneNumber;

  UserModel({
    required this.phoneNumber,
    required this.email,
    required this.fullName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      phoneNumber: json['phoneNumber'],
      fullName: json['fullName'] ,
      email: json['email'],
    );
  }
}