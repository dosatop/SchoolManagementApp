class AdminAcademicTermRequestModel {
final String academicSessionId;
final String term;
final DateTime startDate;
final DateTime endDate;
final bool isCurrent;

AdminAcademicTermRequestModel({
required this.academicSessionId,
required this.term,
required this.startDate,
required this.endDate,
this.isCurrent = false,
});

Map<String, dynamic> toJson() {
return {
'academicSessionId': academicSessionId,
'term': term,
'startDate': startDate.toIso8601String(),
'endDate': endDate.toIso8601String(),
'isCurrent': isCurrent,
};
}
}