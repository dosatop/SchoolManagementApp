import 'package:flutter/material.dart';
import 'package:app/features/study/models/study_model.dart';

class StudyDetailsPage extends StatelessWidget {
  final StudyModel study;

  const StudyDetailsPage({super.key, required this.study});

  @override
  Widget build(BuildContext context) {
    final progressPercent = (study.progress * 100).round();
    final isCompleted = study.progress >= 1;

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
                    'Study Details',
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
                    // HERO CARD
                    _buildHeroCard(context, progressPercent),

                    const SizedBox(height: 25),

                    // OVERVIEW
                    const Text(
                      'About This Lesson',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F313D),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        study.description,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // WHAT YOU'LL LEARN
                    const Text(
                      "What You'll Learn",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F313D),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _lessonPoint(
                      'Understand the main concepts of ${study.title}.',
                    ),

                    _lessonPoint('Learn important principles and examples.'),

                    _lessonPoint('Practice what you have learned.'),

                    _lessonPoint('Review the lesson with a short assessment.'),

                    const SizedBox(height: 25),

                    // LESSON CONTENT
                    const Text(
                      'Lesson Content',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F313D),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _contentCard(
                      number: '01',
                      title: 'Introduction',
                      subtitle: 'Introduction to the topic',
                      icon: Icons.play_circle_outline,
                      completed: study.progress > 0,
                    ),

                    _contentCard(
                      number: '02',
                      title: 'Main Concepts',
                      subtitle: 'Learn the key concepts',
                      icon: Icons.menu_book_outlined,
                      completed: study.progress >= 0.5,
                    ),

                    _contentCard(
                      number: '03',
                      title: 'Examples & Practice',
                      subtitle: 'Practice what you have learned',
                      icon: Icons.edit_note_outlined,
                      completed: study.progress >= 0.75,
                    ),

                    _contentCard(
                      number: '04',
                      title: 'Quick Assessment',
                      subtitle: 'Test your understanding',
                      icon: Icons.quiz_outlined,
                      completed: isCompleted,
                    ),

                    const SizedBox(height: 25),

                    // PROGRESS
                    const Text(
                      'Your Progress',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F313D),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Lesson progress',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2F313D),
                                ),
                              ),
                              Text(
                                '$progressPercent%',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: study.color,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: study.progress,
                              minHeight: 9,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                study.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ACTION BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Open lesson player here
                        },
                        icon: Icon(
                          isCompleted
                              ? Icons.replay
                              : study.progress > 0
                              ? Icons.play_arrow
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          isCompleted
                              ? 'Review Lesson'
                              : study.progress > 0
                              ? 'Continue Studying'
                              : 'Start Lesson',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF091993),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, int progressPercent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: study.color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      study.subject,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      study.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              _heroInfo(Icons.access_time_outlined, study.duration),

              const SizedBox(width: 20),

              _heroInfo(Icons.menu_book_outlined, 'Lesson'),
            ],
          ),

          const SizedBox(height: 22),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your progress',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                '$progressPercent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: study.progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _lessonPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: const Color(0xFF091993).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 14, color: Color(0xFF091993)),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentCard({
    required String number,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool completed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
              color: study.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: study.color, size: 22),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number  $title',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F313D),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          Icon(
            completed ? Icons.check_circle : Icons.chevron_right,
            color: completed ? Colors.green : Colors.grey,
            size: 22,
          ),
        ],
      ),
    );
  }
}
