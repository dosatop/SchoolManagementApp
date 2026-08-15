class CreateClassRequest {
   final String name;

  CreateClassRequest({
        required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
          'name': name,
    };
  }
}