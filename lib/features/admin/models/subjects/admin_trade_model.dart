class AdminTradeModel {
  final String tradeId;
  final String schoolId;
  final String tradeName;
  final String code;

  const AdminTradeModel({
    required this.tradeId,
    required this.schoolId,
    required this.tradeName,
    required this.code,
  });

  factory AdminTradeModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminTradeModel(
      tradeId: (json['id'] ?? json['tradeId'] ?? '').toString(),
      schoolId: (json['schoolId'] ?? '').toString(),
      tradeName: (json['name'] ?? json['tradeName'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tradeId': tradeId,
      'schoolId': schoolId,
      'tradeName': tradeName,
      'code': code,
    };
  }
}
