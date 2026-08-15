class ParentResultModel {
  final String id;
  final String subjectId;
  final String subjectName;
  final double testScore;
  final double examScore;
  final double score;
  final String grade;
  final String remark;
  final String term;

  ParentResultModel({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.testScore,
    required this.examScore,
    required this.score,
    required this.grade,
    required this.remark, required this.term,
  });

  factory ParentResultModel.fromJson(Map<String, dynamic> json) {
    return ParentResultModel(
      id: json['id']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      subjectName: json['subjectName']?.toString() ?? '',
      testScore: _toDouble(json['testScore']),
      examScore: _toDouble(json['examScore']),
      score: _toDouble(json['score']),
      grade: json['grade']?.toString() ?? '',
      remark: json['remark']?.toString() ?? '', 
      term:  json['term']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'testScore': testScore,
      'examScore': examScore,
      'score': score,
      'grade': grade,
      'remark': remark,
      'term': term,
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}
