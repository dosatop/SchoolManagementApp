import 'package:flutter/material.dart';

class TeacherModel {
  final String id;
  final String name;
  final String subject;
  final String department;
  final String email;
  final String phone;
  final String room;
  final String experience;
  final String qualification;
  final String bio;
  final int classes;
  final int students;
  final Color color;
  final IconData icon;

  const TeacherModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.department,
    required this.email,
    required this.phone,
    required this.room,
    required this.experience,
    required this.qualification,
    required this.bio,
    required this.classes,
    required this.students,
    required this.color,
    required this.icon,
  });
}