class AdminResultModel {
  final String resultId;
  final String schoolId;

  final String studentId;
  final String studentName;
  final String studentNumber;

  final String classId;
  final String className;

  final String subjectId;
  final String subjectName;
  final String subjectCode;

  final String session;
  final String term;

  final dynamic testScore;
  final dynamic examScore; // nullable
  final dynamic score;

  final String grade;
  final String remark;

  final DateTime? createdAt;

  AdminResultModel({
    required this.resultId,
    required this.schoolId,
    required this.studentId,
    required this.studentName,
    required this.studentNumber,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.session,
    required this.term,
    required this.testScore,
    this.examScore, // nullable
    required this.score,
    required this.grade,
    required this.remark,
    this.createdAt,
  });

  factory AdminResultModel.fromJson(Map<String, dynamic> json) {
    return AdminResultModel(
      resultId: json['resultId'] ?? '',
      schoolId: json['schoolId'] ?? '',

      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      studentNumber: json['studentNumber'] ?? '',

      classId: json['classId'] ?? '',
      className: json['className'] ?? '',

      subjectId: json['subjectId'] ?? '',
      subjectName: json['subjectName'] ?? '',
      subjectCode: json['subjectCode'] ?? '',

      session: json['session'] ?? '',
      term: json['term'] ?? '',

      testScore: json['testScore'] ?? 0,

      // IMPORTANT:
      // Don't convert null to 0.
      examScore: json['examScore'],

      score: json['score'],

      grade: json['grade'] ?? '',
      remark: json['remark'] ?? '',

      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resultId': resultId,
      'schoolId': schoolId,

      'studentId': studentId,
      'studentName': studentName,
      'studentNumber': studentNumber,

      'classId': classId,
      'className': className,

      'subjectId': subjectId,
      'subjectName': subjectName,
      'subjectCode': subjectCode,

      'session': session,
      'term': term,

      'testScore': testScore,
      'examScore': examScore,
      'score': score,

      'grade': grade,
      'remark': remark,

      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class AdminResultsResponse {
  final String schoolId;
  final String currentSession;
  final String currentTerm;
  final int count;
  final List<AdminResultModel> results;

  AdminResultsResponse({
    required this.schoolId,
    required this.currentSession,
    required this.currentTerm,
    required this.count,
    required this.results,
  });

  factory AdminResultsResponse.fromJson(Map<String, dynamic> json) {
    return AdminResultsResponse(
      schoolId: json['schoolId'] ?? '',
      currentSession: json['currentSession'] ?? '',
      currentTerm: json['currentTerm'] ?? '',
      count: json['count'] ?? 0,
      results: (json['results'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                AdminResultModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class CreateAdminResultRequest {
  final String studentId;
  final String classId;
  final String subjectId;
  final dynamic testScore;
  final dynamic examScore;
  final String remark;

  const CreateAdminResultRequest({
    required this.studentId,
    required this.classId,
    required this.subjectId,
    this.testScore,
    this.examScore,
    required this.remark,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'studentId': studentId,
      'classId': classId,
      'subjectId': subjectId,
      'remark': remark,
    };

    if (testScore != null) {
      data['testScore'] = testScore;
    }

    if (examScore != null) {
      data['examScore'] = examScore;
    }

    return data;
  }
}

class UpdateAdminResultRequest {
  final dynamic testScore;
  final dynamic examScore;
  final String remark;

  UpdateAdminResultRequest({
    required this.testScore,
    required this.examScore,
    required this.remark,
  });

  Map<String, dynamic> toJson() {
    return {'testScore': testScore, 'examScore': examScore, 'remark': remark};
  }
}
