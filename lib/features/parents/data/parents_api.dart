import 'package:app/core/network/dio_client.dart';
import 'package:app/features/parents/models/parent_child_model.dart';
import 'package:app/features/parents/models/parent_model.dart';
import 'package:app/features/parents/models/parent_result_model.dart';

// ==================================================================
// PARENT API — every parent endpoint in one place
// ==================================================================
// Session/term are optional on results, attendance and assignments:
// leave them out and the backend uses the school's current period.
//
// All child routes are built from _child(). If your ParentController
// uses a different prefix, change it there only.

class ParentApi {
  ParentApi(this.dioClient);

  final DioClient dioClient;

  String _child(String studentId) => '/parent/children/$studentId';

  // ================================================================
  // PROFILE + CHILDREN (typed)
  // ================================================================

  // GET /parent/profile
  Future<ParentModel> getProfile() async {
    final response = await dioClient.dio.get('/parent/profile');
    return ParentModel.fromJson(_map(_unwrap(response.data)));
  }

  // GET /parent/profile — raw JSON:
  // { parentId, fullName, email, phoneNumber, schoolId, schoolName,
  //   childrenCount }
  Future<dynamic> getProfileData() async {
    final response = await dioClient.dio.get('/parent/profile');
    return _unwrap(response.data);
  }

  // GET /parent/children
  Future<List<ParentChildModel>> getChildren() async {
    final response = await dioClient.dio.get('/parent/children');
    return _list(_unwrap(response.data), ['children'])
        .map((e) => ParentChildModel.fromJson(_map(e)))
        .toList();
  }

  // GET /parent/children/{studentId}
  Future<ParentChildModel> getChild(String studentId) async {
    final response = await dioClient.dio.get(_child(studentId));
    return ParentChildModel.fromJson(_map(_unwrap(response.data)));
  }

  // ================================================================
  // CHILD DATA (raw JSON — pages read it with tolerant helpers)
  // ================================================================

  // GET /parent/children/{studentId}/class
  Future<dynamic> getChildClass(String studentId) async {
    final response = await dioClient.dio.get('${_child(studentId)}/class');
    return _unwrap(response.data);
  }

  // GET /parent/children/{studentId}/subjects
  Future<dynamic> getChildSubjects(String studentId) async {
    final response = await dioClient.dio.get('${_child(studentId)}/subjects');
    return _unwrap(response.data);
  }

  // GET /parent/children/{studentId}/results[?session=&term=]
  Future<dynamic> getChildResultsData(
    String studentId, {
    String? session,
    String? term,
  }) async {
    final response = await dioClient.dio.get(
      '${_child(studentId)}/results',
      queryParameters: _period(session, term),
    );
    return _unwrap(response.data);
  }

  // GET /parent/children/{studentId}/attendance[?session=&term=]
  Future<dynamic> getChildAttendance(
    String studentId, {
    String? session,
    String? term,
  }) async {
    final response = await dioClient.dio.get(
      '${_child(studentId)}/attendance',
      queryParameters: _period(session, term),
    );
    return _unwrap(response.data);
  }

  // GET /parent/children/{studentId}/assignments[?session=&term=]
  Future<dynamic> getChildAssignments(
    String studentId, {
    String? session,
    String? term,
  }) async {
    final response = await dioClient.dio.get(
      '${_child(studentId)}/assignments',
      queryParameters: _period(session, term),
    );
    return _unwrap(response.data);
  }

  // GET /parent/children/{studentId}/assignments/{assignmentId}
  Future<dynamic> getChildAssignment(
    String studentId,
    String assignmentId,
  ) async {
    final response = await dioClient.dio.get(
      '${_child(studentId)}/assignments/$assignmentId',
    );
    return _unwrap(response.data);
  }

  // ================================================================
  // LEGACY: typed results (kept so older code still compiles)
  // ================================================================

  Future<List<ParentResultModel>> getChildResults(
    String studentId,
    String session,
    String term,
  ) async {
    final data = await getChildResultsData(
      studentId,
      session: session,
      term: term,
    );

    return _list(data, ['results'])
        .map((e) => ParentResultModel.fromJson(_map(e)))
        .toList();
  }

  // ================================================================
  // HELPERS
  // ================================================================

  /// Returns `data` from `{ success, data }`, or the body itself.
  dynamic _unwrap(dynamic body) {
    if (body is Map && body.containsKey('data')) return body['data'];
    return body;
  }

  /// A list either directly, or under one of [keys].
  List<dynamic> _list(dynamic data, List<String> keys) {
    if (data is List) return data;
    if (data is Map) {
      for (final k in keys) {
        if (data[k] is List) return data[k] as List;
      }
    }
    return const [];
  }

  Map<String, dynamic> _map(dynamic data) =>
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

  Map<String, dynamic> _period(String? session, String? term) {
    return {
      if (session != null && session.trim().isNotEmpty)
        'session': session.trim(),
      if (term != null && term.trim().isNotEmpty) 'term': term.trim(),
    };
  }
}