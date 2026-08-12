 import 'dart:convert';

String getMessage(String body) {
    try {
      final json = jsonDecode(body);

      if (json is Map) {
        if (json['message'] != null) {
          return json['message'].toString();
        }

        if (json['errors'] is List && json['errors'].isNotEmpty) {
          return json['errors'][0].toString();
        }
      }

      return body;
    } catch (_) {
      return body;
    }
  }