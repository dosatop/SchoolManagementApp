import 'package:flutter/material.dart';

class StudentResultsPage extends StatelessWidget {
  const StudentResultsPage({super.key});

  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF7F7F7);
  static const Color textDark = Color(0xFF2F313D);

  @override
  Widget build(BuildContext context) {
    final results = [
      {
        'subject': 'Mathematics',
        'score': '85',
        'grade': 'A',
        'color': Colors.green,
      },
      {
        'subject': 'English Language',
        'score': '78',
        'grade': 'B',
        'color': Colors.blue,
      },
      {
        'subject': 'Basic Science',
        'score': '91',
        'grade': 'A',
        'color': Colors.green,
      },
      {
        'subject': 'Social Studies',
        'score': '74',
        'grade': 'B',
        'color': Colors.blue,
      },
      {
        'subject': 'Computer Studies',
        'score': '88',
        'grade': 'A',
        'color': Colors.green,
      },
    ];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: textDark,
        title: const Text(
          'Results',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primary, Color(0xFF1729B8)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Performance',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),

                SizedBox(height: 8),

                Text(
                  '83%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Excellent performance',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Subject Results',
            style: TextStyle(
              color: textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          ...results.map(
            (result) => _resultCard(
              subject: result['subject'] as String,
              score: result['score'] as String,
              grade: result['grade'] as String,
              color: result['color'] as Color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultCard({
    required String subject,
    required String score,
    required String grade,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              subject,
              style: const TextStyle(
                color: textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Text(
            '$score%',
            style: const TextStyle(
              color: textDark,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(width: 18),

          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              grade,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
