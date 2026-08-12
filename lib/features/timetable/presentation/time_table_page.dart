import 'package:app/core/Widgets/Cards/time_table_card.dart';
import 'package:app/features/timetable/models/time_table_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TimeTablePage extends StatefulWidget {
  const TimeTablePage({super.key});

  @override
  State<TimeTablePage> createState() => _TimeTablePageState();
}

class _TimeTablePageState extends State<TimeTablePage> {
  int selectedDay = 0;

  final List<Map<String, String>> days = [
    {'day': 'Mon', 'date': '10'},
    {'day': 'Tue', 'date': '11'},
    {'day': 'Wed', 'date': '12'},
    {'day': 'Thu', 'date': '13'},
    {'day': 'Fri', 'date': '14'},
  ];

  final List<TimetableModel> timetable = [
    TimetableModel(
      id: '1',
      subject: 'Mathematics',
      teacher: 'Mr. Anderson',
      room: 'Room 12',
      day: 'Mon',
      startTime: '8:00 AM',
      endTime: '9:00 AM',
      classType: 'Regular Class',
      description:
          'Mathematics class covering algebra, equations and problem solving.',
      color: Color(0xFF091993),
      icon: Icons.calculate_outlined,
    ),

    TimetableModel(
      id: '2',
      subject: 'English',
      teacher: 'Mrs. Williams',
      room: 'Room 8',
      day: 'Mon',
      startTime: '9:00 AM',
      endTime: '10:00 AM',
      classType: 'Regular Class',
      description:
          'English language and literature class covering reading and writing.',
      color: Colors.orange,
      icon: Icons.menu_book_outlined,
    ),

    TimetableModel(
      id: '3',
      subject: 'Biology',
      teacher: 'Dr. Johnson',
      room: 'Lab 2',
      day: 'Mon',
      startTime: '10:30 AM',
      endTime: '11:30 AM',
      classType: 'Laboratory Class',
      description:
          'Biology practical covering the human body and living organisms.',
      color: Colors.green,
      icon: Icons.biotech_outlined,
    ),

    TimetableModel(
      id: '4',
      subject: 'Physics',
      teacher: 'Mr. Smith',
      room: 'Room 15',
      day: 'Mon',
      startTime: '12:00 PM',
      endTime: '1:00 PM',
      classType: 'Regular Class',
      description: 'Physics class covering motion, forces and basic mechanics.',
      color: Colors.purple,
      icon: Icons.science_outlined,
    ),

    TimetableModel(
      id: '5',
      subject: 'Chemistry',
      teacher: 'Mrs. Davis',
      room: 'Lab 1',
      day: 'Tue',
      startTime: '8:00 AM',
      endTime: '9:00 AM',
      classType: 'Laboratory Class',
      description:
          'Chemistry practical covering chemical reactions and compounds.',
      color: Colors.red,
      icon: Icons.science_outlined,
    ),

    TimetableModel(
      id: '6',
      subject: 'Mathematics',
      teacher: 'Mr. Anderson',
      room: 'Room 12',
      day: 'Tue',
      startTime: '9:00 AM',
      endTime: '10:00 AM',
      classType: 'Regular Class',
      description:
          'Mathematics class covering algebra, equations and problem solving.',
      color: Color(0xFF091993),
      icon: Icons.calculate_outlined,
    ),

    TimetableModel(
      id: '7',
      subject: 'History',
      teacher: 'Mr. Brown',
      room: 'Room 5',
      day: 'Tue',
      startTime: '10:30 AM',
      endTime: '11:30 AM',
      classType: 'Regular Class',
      description:
          'History class covering important historical events and civilizations.',
      color: Colors.brown,
      icon: Icons.history_edu_outlined,
    ),

    TimetableModel(
      id: '8',
      subject: 'Physical Education',
      teacher: 'Coach Mike',
      room: 'Sports Field',
      day: 'Tue',
      startTime: '12:00 PM',
      endTime: '1:00 PM',
      classType: 'Practical Class',
      description:
          'Physical education class involving sports, fitness and exercises.',
      color: Colors.teal,
      icon: Icons.sports_soccer_outlined,
    ),

    TimetableModel(
      id: '9',
      subject: 'English',
      teacher: 'Mrs. Williams',
      room: 'Room 8',
      day: 'Wed',
      startTime: '8:00 AM',
      endTime: '9:00 AM',
      classType: 'Regular Class',
      description:
          'English language and literature class covering reading and writing.',
      color: Colors.orange,
      icon: Icons.menu_book_outlined,
    ),

    TimetableModel(
      id: '10',
      subject: 'Physics',
      teacher: 'Mr. Smith',
      room: 'Room 15',
      day: 'Wed',
      startTime: '9:00 AM',
      endTime: '10:00 AM',
      classType: 'Regular Class',
      description: 'Physics class covering motion, forces and basic mechanics.',
      color: Colors.purple,
      icon: Icons.science_outlined,
    ),

    TimetableModel(
      id: '11',
      subject: 'Computer Science',
      teacher: 'Mr. Adams',
      room: 'ICT Lab',
      day: 'Wed',
      startTime: '10:30 AM',
      endTime: '11:30 AM',
      classType: 'Practical Class',
      description:
          'Computer science class covering programming and computer systems.',
      color: Colors.blue,
      icon: Icons.computer_outlined,
    ),

    TimetableModel(
      id: '12',
      subject: 'Biology',
      teacher: 'Dr. Johnson',
      room: 'Lab 2',
      day: 'Wed',
      startTime: '12:00 PM',
      endTime: '1:00 PM',
      classType: 'Laboratory Class',
      description:
          'Biology practical covering the human body and living organisms.',
      color: Colors.green,
      icon: Icons.biotech_outlined,
    ),

    TimetableModel(
      id: '13',
      subject: 'Mathematics',
      teacher: 'Mr. Anderson',
      room: 'Room 12',
      day: 'Thu',
      startTime: '8:00 AM',
      endTime: '9:00 AM',
      classType: 'Regular Class',
      description:
          'Mathematics class covering algebra, equations and problem solving.',
      color: Color(0xFF091993),
      icon: Icons.calculate_outlined,
    ),

    TimetableModel(
      id: '14',
      subject: 'Chemistry',
      teacher: 'Mrs. Davis',
      room: 'Lab 1',
      day: 'Thu',
      startTime: '9:00 AM',
      endTime: '10:00 AM',
      classType: 'Laboratory Class',
      description:
          'Chemistry practical covering chemical reactions and compounds.',
      color: Colors.red,
      icon: Icons.science_outlined,
    ),

    TimetableModel(
      id: '15',
      subject: 'English',
      teacher: 'Mrs. Williams',
      room: 'Room 8',
      day: 'Thu',
      startTime: '10:30 AM',
      endTime: '11:30 AM',
      classType: 'Regular Class',
      description:
          'English language and literature class covering reading and writing.',
      color: Colors.orange,
      icon: Icons.menu_book_outlined,
    ),

    TimetableModel(
      id: '16',
      subject: 'History',
      teacher: 'Mr. Brown',
      room: 'Room 5',
      day: 'Fri',
      startTime: '8:00 AM',
      endTime: '9:00 AM',
      classType: 'Regular Class',
      description:
          'History class covering important historical events and civilizations.',
      color: Colors.brown,
      icon: Icons.history_edu_outlined,
    ),

    TimetableModel(
      id: '17',
      subject: 'Computer Science',
      teacher: 'Mr. Adams',
      room: 'ICT Lab',
      day: 'Fri',
      startTime: '9:00 AM',
      endTime: '10:00 AM',
      classType: 'Practical Class',
      description:
          'Computer science class covering programming and computer systems.',
      color: Colors.blue,
      icon: Icons.computer_outlined,
    ),

    TimetableModel(
      id: '18',
      subject: 'Physical Education',
      teacher: 'Coach Mike',
      room: 'Sports Field',
      day: 'Fri',
      startTime: '10:30 AM',
      endTime: '11:30 AM',
      classType: 'Practical Class',
      description:
          'Physical education class involving sports, fitness and exercises.',
      color: Colors.teal,
      icon: Icons.sports_soccer_outlined,
    ),
  ];

  List<TimetableModel> get selectedClasses {
    final selectedDayName = days[selectedDay]['day'];

    return timetable.where((lesson) => lesson.day == selectedDayName).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDayName = days[selectedDay]['day'];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackButton(),

                  const Text(
                    'Time Table',
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
                      Icons.notifications_outlined,
                      size: 30,
                      color: Color(0xFF2F313D),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // DAYS
              SizedBox(
                height: 85,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final isSelected = selectedDay == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDay = index;
                        });
                      },
                      child: Container(
                        width: 62,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF091993)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF091993)
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              day['day']!,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white70
                                    : Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              day['date']!,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF2F313D),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // DAY TITLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$selectedDayName Schedule',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F313D),
                    ),
                  ),

                  Text(
                    '${selectedClasses.length} Classes',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // CLASSES
              Expanded(
                child: selectedClasses.isEmpty
                    ? const Center(
                        child: Text(
                          'No classes scheduled',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: selectedClasses.length,
                        itemBuilder: (context, index) {
                          final lesson = selectedClasses[index];

                          return TimetableCard(
                            lesson: lesson,
                            onTap: () {
                              context.push(
                                '/timetable/${lesson.id}',
                                extra: lesson,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
