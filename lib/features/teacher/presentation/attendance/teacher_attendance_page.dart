import 'package:flutter/material.dart';

class TeacherAttendancePage extends StatefulWidget {
  const TeacherAttendancePage({super.key});

  @override
  State<TeacherAttendancePage> createState() => _TeacherAttendancePageState();
}

class _TeacherAttendancePageState extends State<TeacherAttendancePage> {
  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  String selectedClass = 'JSS 1A';

  final Map<String, String> attendance = {
    'John Doe': 'Present',
    'Mary James': 'Present',
    'David Smith': 'Absent',
    'Sarah Williams': 'Present',
    'Daniel Brown': 'Late',
  };

  @override
  Widget build(BuildContext context) {
    final present =
        attendance.values.where((value) => value == 'Present').length;
    final absent =
        attendance.values.where((value) => value == 'Absent').length;
    final late = attendance.values.where((value) => value == 'Late').length;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Attendance',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _classSelector(),
          const SizedBox(height: 15),
          _dateSelector(),
          const SizedBox(height: 18),

          Row(
            children: [
              _summary('Present', present, Colors.green),
              const SizedBox(width: 8),
              _summary('Absent', absent, Colors.red),
              const SizedBox(width: 8),
              _summary('Late', late, Colors.orange),
            ],
          ),

          const SizedBox(height: 22),

          const Text(
            'Students',
            style: TextStyle(
              color: textDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          ...attendance.entries.map(
            (entry) => _studentAttendance(entry.key, entry.value),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: 0,
        onDestinationSelected: (index) {},
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Classes',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _classSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedClass,
          isExpanded: true,
          items: ['JSS 1A', 'JSS 1B', 'SSS 1A', 'SSS 2B']
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => selectedClass = value);
            }
          },
        ),
      ),
    );
  }

  Widget _dateSelector() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            color: primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Today, September 10, 2026',
              style: TextStyle(
                color: textDark,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey.shade600,
          ),
        ],
      ),
    );
  }

  Widget _summary(String title, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentAttendance(String name, String status) {
    Color color;

    switch (status) {
      case 'Absent':
        color = Colors.red;
        break;
      case 'Late':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: primary.withOpacity(.08),
            child: const Icon(
              Icons.person_outline_rounded,
              color: primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: textDark,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}