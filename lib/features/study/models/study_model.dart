import 'package:flutter/material.dart';

class StudyModel {
  final String id;
  final String subject;
  final String title;
  final String description;
  final String duration;
  final String imageUrl;
  final Color color;
  final double progress;

  const StudyModel({
    required this.id,
    required this.subject,
    required this.title,
    required this.description,
    required this.duration,
    required this.imageUrl,
    required this.color,
    required this.progress,
  });
}