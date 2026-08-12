class User {
  // final String id;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String userName;

  User({
    // required this.id,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.userName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'],
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      userName: json['userName'],
    );
  }
}
