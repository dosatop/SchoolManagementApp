class EmailNormalizer {
  static String normalize(String email) {
    return email
        .trim()
        .toLowerCase();
  }
}