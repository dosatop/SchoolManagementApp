import 'package:flutter/material.dart';

class TutorModel {
  final String id;
  final String name;
  final String subject;
  final String qualification;
  final String experience;
  final double rating;
  final String imageUrl;
  final Color color;

  const TutorModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.qualification,
    required this.experience,
    required this.rating,
    required this.imageUrl,
    required this.color,
  });
}