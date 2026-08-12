class ResultCalculator {
  static double calculateTotal({
    required double ca1,
    required double ca2,
    required double exam,
  }) {
    return ca1 + ca2 + exam;
  }

  static String calculateGrade(double total) {
    if (total >= 70) return 'A';
    if (total >= 60) return 'B';
    if (total >= 50) return 'C';
    if (total >= 45) return 'D';
    if (total >= 40) return 'E';
    return 'F';
  }
}