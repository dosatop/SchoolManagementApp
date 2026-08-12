import 'dart:ui';

class Assignment {
  final String id;
  final String subject;
  final String title;
  final String description;
  final String dueDate;
  final String status;
  final Color color;

  Assignment({
    required this.id,
    required this.subject,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.color,
  });
}