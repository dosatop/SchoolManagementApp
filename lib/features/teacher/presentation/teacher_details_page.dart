import 'package:app/features/teacher/models/teacher_model.dart';
import 'package:flutter/material.dart';

class TeacherDetailsPage extends StatelessWidget {
  final TeacherModel teacher;

  const TeacherDetailsPage({super.key, required this.teacher});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackButton(),

                  const Text(
                    'Teacher Details',
                    style: TextStyle(
                      fontSize: 24,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F313D),
                    ),
                  ),

                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.more_vert,
                      size: 28,
                      color: Color(0xFF2F313D),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =========================
                    // TEACHER PROFILE CARD
                    // =========================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: teacher.color,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          // PROFILE ICON
                          Container(
                            width: 85,
                            height: 85,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: Colors.white,
                              size: 45,
                            ),
                          ),

                          const SizedBox(height: 15),

                          Text(
                            teacher.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            teacher.subject,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 3),

                          Text(
                            teacher.department,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // STATS
                          Row(
                            children: [
                              Expanded(
                                child: _profileStat(
                                  value: '${teacher.classes}',
                                  label: 'Classes',
                                ),
                              ),
                              Expanded(
                                child: _profileStat(
                                  value: '${teacher.students}',
                                  label: 'Students',
                                ),
                              ),
                              Expanded(
                                child: _profileStat(
                                  value: teacher.experience,
                                  label: 'Experience',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // =========================
                    // CONTACT INFORMATION
                    // =========================
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F313D),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _infoCard(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: teacher.email,
                    ),

                    _infoCard(
                      icon: Icons.phone_outlined,
                      title: 'Phone',
                      value: teacher.phone,
                    ),

                    _infoCard(
                      icon: Icons.location_on_outlined,
                      title: 'Classroom',
                      value: teacher.room,
                    ),

                    const SizedBox(height: 15),

                    // =========================
                    // PROFESSIONAL INFORMATION
                    // =========================
                    const Text(
                      'Professional Information',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F313D),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _infoCard(
                      icon: Icons.school_outlined,
                      title: 'Qualification',
                      value: teacher.qualification,
                    ),

                    _infoCard(
                      icon: Icons.work_outline,
                      title: 'Experience',
                      value: teacher.experience,
                    ),

                    _infoCard(
                      icon: Icons.menu_book_outlined,
                      title: 'Subject',
                      value: teacher.subject,
                    ),

                    const SizedBox(height: 15),

                    // =========================
                    // ABOUT TEACHER
                    // =========================
                    const Text(
                      'About Teacher',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F313D),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        teacher.bio,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // =========================
                    // TEACHER SUMMARY
                    // =========================
                    const Text(
                      'Teaching Summary',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F313D),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _summaryCard(
                            icon: Icons.class_outlined,
                            value: '${teacher.classes}',
                            label: 'Classes',
                            color: teacher.color,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: _summaryCard(
                            icon: Icons.groups_outlined,
                            value: '${teacher.students}',
                            label: 'Students',
                            color: teacher.color,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileStat({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: teacher.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: teacher.color),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF2F313D),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),

          const SizedBox(height: 12),

          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F313D),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
