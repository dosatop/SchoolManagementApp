class CreateSchoolRequest {
  final String name;
  final String address;
  final String? email;
  final String? phoneNumber;

  const CreateSchoolRequest({
    required this.name,
    required this.address,
    this.email,
    this.phoneNumber,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'email': email,
      'phoneNumber': phoneNumber,
    };
  }
}