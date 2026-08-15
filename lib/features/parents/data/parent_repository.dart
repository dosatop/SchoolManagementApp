import 'package:app/features/parents/data/parents_api.dart';
import 'package:app/features/parents/models/parent_model.dart';
import 'package:app/features/parents/models/parent_child_model.dart';
import 'package:app/features/parents/models/parent_result_model.dart';

class ParentRepository {
  final ParentApi api;

  ParentRepository(this.api);

  Future<ParentModel> getProfile() async {
    return await api.getProfile();
  }

  Future<List<ParentChildModel>> getChildren() async {
    return await api.getChildren();
  }

  Future<ParentChildModel> getChild(String studentId) async {
    return await api.getChild(studentId);
  }

  Future<List<ParentResultModel>> getChildResults(
    String studentId,
    String session,
    String term,
  ) async {
    return await api.getChildResults(studentId, session, term);
  }
}
