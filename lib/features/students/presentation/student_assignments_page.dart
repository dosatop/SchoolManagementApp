import 'package:flutter/material.dart';

class StudentAssignmentsPage extends StatelessWidget {
  const StudentAssignmentsPage({super.key});

  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF7F7F7);
  static const Color textDark = Color(0xFF2F313D);

  @override
  Widget build(BuildContext context) {
    final assignments = [
      {
        'subject': 'Mathematics',
        'title': 'Algebra Exercise',
        'due': 'Aug 14, 2026',
        'status': 'Pending',
        'color': Colors.orange,
      },
      {
        'subject': 'English Language',
        'title': 'Essay Writing',
        'due': 'Aug 15, 2026',
        'status': 'Pending',
        'color': Colors.purple,
      },
      {
        'subject': 'Basic Science',
        'title': 'Human Body Assignment',
        'due': 'Aug 17, 2026',
        'status': 'Submitted',
        'color': Colors.green,
      },
      {
        'subject': 'Computer Studies',
        'title': 'Computer Parts',
        'due': 'Aug 20, 2026',
        'status': 'Pending',
        'color': Colors.blue,
      },
    ];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: textDark,
        title: const Text(
          'Assignments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: assignments.length,
        itemBuilder: (context, index) {
          final assignment = assignments[index];

          final color = assignment['color'] as Color;

          final submitted = assignment['status'] == 'Submitted';

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
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
                    Expanded(
                      child: Text(
                        assignment['title'] as String,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    _status(
                      submitted ? 'Submitted' : 'Pending',
                      submitted ? Colors.green : Colors.orange,
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  assignment['subject'] as String,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Due ${assignment['due']}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _status(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
