import 'package:app/features/teacher/models/teacher_model.dart';
import 'package:app/core/Widgets/Cards/teacher_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TeacherPage extends StatelessWidget {
  const TeacherPage({super.key});

  static const List<TeacherModel> teachers = [
    TeacherModel(
      id: '1',
      name: 'Mr. Anderson',
      subject: 'Mathematics',
      department: 'Mathematics Department',
      email: 'anderson@school.com',
      phone: '+234 801 234 5678',
      room: 'Room 12',
      experience: '8 Years',
      qualification: 'B.Sc. Mathematics',
      bio:
          'Mr. Anderson is a mathematics teacher who specializes in algebra, geometry, equations and problem solving.',
      classes: 5,
      students: 142,
      color: Color(0xFF091993),
      icon: Icons.calculate_outlined,
    ),

    TeacherModel(
      id: '2',
      name: 'Mrs. Williams',
      subject: 'English',
      department: 'Languages Department',
      email: 'williams@school.com',
      phone: '+234 802 345 6789',
      room: 'Room 8',
      experience: '6 Years',
      qualification: 'B.A. English Language',
      bio:
          'Mrs. Williams teaches English language and literature with a focus on reading, writing and communication.',
      classes: 4,
      students: 128,
      color: Colors.orange,
      icon: Icons.menu_book_outlined,
    ),

    TeacherModel(
      id: '3',
      name: 'Dr. Johnson',
      subject: 'Biology',
      department: 'Science Department',
      email: 'johnson@school.com',
      phone: '+234 803 456 7890',
      room: 'Lab 2',
      experience: '10 Years',
      qualification: 'Ph.D. Biology',
      bio:
          'Dr. Johnson teaches biology and conducts practical laboratory sessions covering human biology and living organisms.',
      classes: 4,
      students: 116,
      color: Colors.green,
      icon: Icons.biotech_outlined,
    ),

    TeacherModel(
      id: '4',
      name: 'Mr. Smith',
      subject: 'Physics',
      department: 'Science Department',
      email: 'smith@school.com',
      phone: '+234 804 567 8901',
      room: 'Room 15',
      experience: '7 Years',
      qualification: 'B.Sc. Physics',
      bio:
          'Mr. Smith specializes in physics, mechanics, motion, forces and practical science experiments.',
      classes: 4,
      students: 110,
      color: Colors.purple,
      icon: Icons.science_outlined,
    ),

    TeacherModel(
      id: '5',
      name: 'Mrs. Davis',
      subject: 'Chemistry',
      department: 'Science Department',
      email: 'davis@school.com',
      phone: '+234 805 678 9012',
      room: 'Lab 1',
      experience: '9 Years',
      qualification: 'M.Sc. Chemistry',
      bio:
          'Mrs. Davis teaches chemistry with a focus on chemical reactions, compounds and laboratory experiments.',
      classes: 3,
      students: 94,
      color: Colors.red,
      icon: Icons.science_outlined,
    ),

    TeacherModel(
      id: '6',
      name: 'Mr. Adams',
      subject: 'Computer Science',
      department: 'Technology Department',
      email: 'adams@school.com',
      phone: '+234 806 789 0123',
      room: 'ICT Lab',
      experience: '5 Years',
      qualification: 'B.Sc. Computer Science',
      bio:
          'Mr. Adams teaches programming, computer systems and information technology through practical lessons.',
      classes: 3,
      students: 88,
      color: Colors.blue,
      icon: Icons.computer_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final totalStudents = teachers.fold<int>(
      0,
      (sum, teacher) => sum + teacher.students,
    );

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
                    'Teachers',
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

              // SUMMARY
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF091993),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.groups_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),

                        const SizedBox(width: 15),

                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Teaching Staff',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '6 Teachers',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: _stat(
                            value: '${teachers.length}',
                            label: 'Teachers',
                          ),
                        ),
                        Expanded(
                          child: _stat(
                            value: '${teachers.length}',
                            label: 'Subjects',
                          ),
                        ),
                        Expanded(
                          child: _stat(
                            value: '$totalStudents',
                            label: 'Students',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // SECTION TITLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'All Teachers',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F313D),
                    ),
                  ),

                  Text(
                    '${teachers.length} Staff',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // TEACHERS
              Expanded(
                child: ListView.builder(
                  itemCount: teachers.length,
                  itemBuilder: (context, index) {
                    final teacher = teachers[index];

                    return TeacherCard(
                      teacher: teacher,
                      onTap: () {
                        context.push(
                          '/teachers/${teacher.id}',
                          extra: teacher,
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

  Widget _stat({
    required String value,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}