import 'dart:convert';

import 'package:app/core/storage/storage_service.dart';
import 'package:app/core/constants/api_constant.dart';
import 'package:app/core/helpers/email/email_normalizer.dart';
import 'package:http/http.dart' as http;

class EmailService {
  Future<String> sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
  }) async {
    final token = await StorageService().getToken();
    final normalizedEmail = EmailNormalizer.normalize(to);

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/Email/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'to': normalizedEmail,
        'subject': subject,
        'htmlContent': htmlContent,
      }),
    );

    if (response.statusCode != 200) {
      print(response.body);
      throw Exception('Failed to send email: ${response.body}');
    }
    return response.body;
  }
}
