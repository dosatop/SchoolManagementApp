class AdminEditSubjectModel {
  final String name;
  final String code;
  final int type;
  final String? departmentId;
  final String? tradeId;

  const AdminEditSubjectModel({
    required this.name,
    required this.code,
    required this.type,
    this.departmentId,
    this.tradeId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'type': type,
      'departmentId': departmentId,
      'tradeId': tradeId,
    };
  }
}