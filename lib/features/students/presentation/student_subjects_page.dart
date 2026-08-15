import 'package:flutter/material.dart';

class StudentSubjectsPage extends StatelessWidget {
  const StudentSubjectsPage({super.key});

  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF7F7F7);
  static const Color textDark = Color(0xFF2F313D);

  @override
  Widget build(BuildContext context) {
    final subjects = [
      {
        'name': 'Mathematics',
        'code': 'MTH101',
        'teacher': 'Mr. Adewale',
        'color': Colors.blue,
        'icon': Icons.calculate_outlined,
      },
      {
        'name': 'English Language',
        'code': 'ENG101',
        'teacher': 'Mrs. Johnson',
        'color': Colors.purple,
        'icon': Icons.menu_book_outlined,
      },
      {
        'name': 'Basic Science',
        'code': 'BSC101',
        'teacher': 'Mr. Daniel',
        'color': Colors.green,
        'icon': Icons.science_outlined,
      },
      {
        'name': 'Social Studies',
        'code': 'SST101',
        'teacher': 'Mrs. Grace',
        'color': Colors.orange,
        'icon': Icons.public_outlined,
      },
      {
        'name': 'Computer Studies',
        'code': 'CMP101',
        'teacher': 'Mr. Samuel',
        'color': Colors.teal,
        'icon': Icons.computer_outlined,
      },
      {
        'name': 'Civic Education',
        'code': 'CVE101',
        'teacher': 'Mrs. Esther',
        'color': Colors.red,
        'icon': Icons.people_outline,
      },
    ];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: textDark,
        title: const Text(
          'Subjects',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          final color = subject['color'] as Color;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    subject['icon'] as IconData,
                    color: color,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject['name'] as String,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        subject['code'] as String,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        subject['teacher'] as String,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          );
        },
      ),
    );
  }
}
