import 'package:app/core/network/dio_client.dart';
import 'package:app/features/parents/models/parent_child_model.dart';
import 'package:app/features/parents/models/parent_model.dart';
import 'package:app/features/parents/models/parent_result_model.dart';

class ParentApi {
  final DioClient dioClient;

  ParentApi(this.dioClient);

  // get ParentResultModel => null;

  // ============================================================
  // GET PARENT PROFILE
  // GET /api/parent/profile
  // ============================================================

  Future<ParentModel> getProfile() async {
    final response = await dioClient.dio.get('/parent/profile');

    return ParentModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  // ============================================================
  // GET PARENT CHILDREN
  // GET /api/parent/children
  // ============================================================

  Future<List<ParentChildModel>> getChildren() async {
    final response = await dioClient.dio.get('/parent/children');

    final data = response.data as List;

    return data
        .map(
          (json) => ParentChildModel.fromJson(Map<String, dynamic>.from(json)),
        )
        .toList();
  }

  // ============================================================
  // GET SINGLE CHILD
  // GET /api/parent/children/{studentId}
  // ============================================================

  Future<ParentChildModel> getChild(String studentId) async {
    final response = await dioClient.dio.get('/parent/children/$studentId');

    return ParentChildModel.fromJson(Map<String, dynamic>.from(response.data));
  }

  // ============================================================
  // GET CHILD RESULTS
  // GET /api/parent/children/{studentId}/results
  // ============================================================

  Future<List<ParentResultModel>> getChildResults(
    String studentId,
    String session,
    String term,
  ) async {
    final response = await dioClient.dio.get(
      '/parent/children/$studentId/results',
      queryParameters: {'session': session, 'term': term},
    );

    print('RESULT RESPONSE: ${response.data}');
    print('RESULT TYPE: ${response.data.runtimeType}');

    final data = Map<String, dynamic>.from(response.data);

    final results = data['results'] as List? ?? [];

    return results
        .map(
          (json) => ParentResultModel.fromJson(Map<String, dynamic>.from(json)),
        )
        .toList();
  }
}
