import 'package:flutter/material.dart';

class TimetableModel {
  final String id;
  final String subject;
  final String teacher;
  final String room;
  final String day;
  final String startTime;
  final String endTime;
  final String classType;
  final String description;
  final Color color;
  final IconData icon;

  TimetableModel({
    required this.id,
    required this.subject,
    required this.teacher,
    required this.room,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.classType,
    required this.description,
    required this.color,
    required this.icon,
  });
}
