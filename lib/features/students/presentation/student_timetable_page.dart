import 'package:flutter/material.dart';

class StudentTimetablePage extends StatelessWidget {
  const StudentTimetablePage({super.key});

  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF7F7F7);
  static const Color textDark = Color(0xFF2F313D);

  @override
  Widget build(BuildContext context) {
    final timetable = [
      {
        'day': 'Monday',
        'classes': [
          ['8:00 AM', 'Mathematics'],
          ['9:00 AM', 'English Language'],
          ['10:30 AM', 'Basic Science'],
          ['12:00 PM', 'Computer Studies'],
        ],
      },
      {
        'day': 'Tuesday',
        'classes': [
          ['8:00 AM', 'Social Studies'],
          ['9:00 AM', 'Mathematics'],
          ['10:30 AM', 'Civic Education'],
          ['12:00 PM', 'English Language'],
        ],
      },
      {
        'day': 'Wednesday',
        'classes': [
          ['8:00 AM', 'Basic Science'],
          ['9:00 AM', 'Mathematics'],
          ['10:30 AM', 'Computer Studies'],
          ['12:00 PM', 'Social Studies'],
        ],
      },
      {
        'day': 'Thursday',
        'classes': [
          ['8:00 AM', 'English Language'],
          ['9:00 AM', 'Civic Education'],
          ['10:30 AM', 'Mathematics'],
          ['12:00 PM', 'Basic Science'],
        ],
      },
      {
        'day': 'Friday',
        'classes': [
          ['8:00 AM', 'Computer Studies'],
          ['9:00 AM', 'Social Studies'],
          ['10:30 AM', 'English Language'],
          ['12:00 PM', 'Civic Education'],
        ],
      },
    ];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        foregroundColor: textDark,
        title: const Text(
          'Timetable',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: timetable.map((day) {
          return Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day['day'] as String,
                  style: const TextStyle(
                    color: primary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 14),

                ...(day['classes'] as List<List<String>>).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 75,
                          child: Text(
                            item[0],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        Container(
                          width: 3,
                          height: 35,
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            item[1],
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
