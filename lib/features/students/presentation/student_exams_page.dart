import 'package:flutter/material.dart';

class StudentExamsPage extends StatelessWidget {
  const StudentExamsPage({super.key});

  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF7F7F7);
  static const Color textDark = Color(0xFF2F313D);

  @override
  Widget build(BuildContext context) {
    final exams = [
      {
        'subject': 'Mathematics',
        'date': 'Aug 18, 2026',
        'time': '9:00 AM - 10:30 AM',
        'venue': 'Classroom 1',
      },
      {
        'subject': 'English Language',
        'date': 'Aug 19, 2026',
        'time': '9:00 AM - 10:30 AM',
        'venue': 'Classroom 1',
      },
      {
        'subject': 'Basic Science',
        'date': 'Aug 20, 2026',
        'time': '11:00 AM - 12:30 PM',
        'venue': 'Science Lab',
      },
      {
        'subject': 'Social Studies',
        'date': 'Aug 21, 2026',
        'time': '9:00 AM - 10:30 AM',
        'venue': 'Classroom 2',
      },
    ];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: textDark,
        title: const Text(
          'Exams',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: exams.length,
        itemBuilder: (context, index) {
          final exam = exams[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
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
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.quiz_outlined, color: primary),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        exam['subject']!,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _info(Icons.calendar_today_outlined, exam['date']!),

                const SizedBox(height: 8),

                _info(Icons.access_time_outlined, exam['time']!),

                const SizedBox(height: 8),

                _info(Icons.location_on_outlined, exam['venue']!),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }
}
