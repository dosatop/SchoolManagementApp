class StudentResultModel {
  final String studentId;
  final String studentName;
  final String studentClass;

  double caScore;
  double examScore;

  StudentResultModel({
    required this.studentId,
    required this.studentName,
    required this.studentClass,
    this.caScore = 0,
    this.examScore = 0,
  });

  double get total => caScore + examScore;
}