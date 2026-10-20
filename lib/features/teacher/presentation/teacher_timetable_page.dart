import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TeacherTimetablePage extends ConsumerWidget {
  const TeacherTimetablePage({super.key});

  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
    ];

    return DefaultTabController(
      length: days.length,
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          title: const Text(
            'Timetable',
            style: TextStyle(
              color: textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            labelColor: primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primary,
            tabs: days.map((day) => Tab(text: day)).toList(),
          ),
        ),
        body: TabBarView(
          children: days.map((day) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _class(
                  'Mathematics',
                  'JSS 1',
                  '8:00 AM - 9:00 AM',
                  'Room 101',
                  Colors.blue,
                ),
                _class(
                  'English',
                  'JSS 2',
                  '10:00 AM - 11:00 AM',
                  'Room 203',
                  Colors.green,
                ),
                _class(
                  'Basic Science',
                  'JSS 3',
                  '12:00 PM - 1:00 PM',
                  'Lab 1',
                  Colors.orange,
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _class(
    String subject,
    String className,
    String time,
    String room,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 55,
            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              Icons.menu_book_outlined,
              color: color,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    color: textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  className,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: const TextStyle(
                    color: primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  room,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}