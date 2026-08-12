import 'package:flutter/material.dart';

class ExamPage extends StatefulWidget {
  const ExamPage({super.key});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  String selectedTerm = 'First Term';

  final List<String> terms = [
    'First Term',
    'Second Term',
    'Third Term',
  ];

  final List<Map<String, dynamic>> exams = [
    {
      'subject': 'Mathematics',
      'date': 'Aug 18, 2026',
      'day': 'Tuesday',
      'time': '9:00 AM - 11:00 AM',
      'venue': 'Exam Hall A',
      'type': 'Theory',
      'status': 'Upcoming',
      'color': Color(0xFF091993),
      'icon': Icons.calculate_outlined,
    },
    {
      'subject': 'English',
      'date': 'Aug 20, 2026',
      'day': 'Thursday',
      'time': '9:00 AM - 11:00 AM',
      'venue': 'Exam Hall B',
      'type': 'Theory',
      'status': 'Upcoming',
      'color': Colors.orange,
      'icon': Icons.menu_book_outlined,
    },
    {
      'subject': 'Biology',
      'date': 'Aug 24, 2026',
      'day': 'Monday',
      'time': '10:00 AM - 12:00 PM',
      'venue': 'Science Lab',
      'type': 'Practical',
      'status': 'Upcoming',
      'color': Colors.green,
      'icon': Icons.biotech_outlined,
    },
    {
      'subject': 'Physics',
      'date': 'Aug 26, 2026',
      'day': 'Wednesday',
      'time': '9:00 AM - 11:00 AM',
      'venue': 'Exam Hall A',
      'type': 'Theory',
      'status': 'Upcoming',
      'color': Colors.purple,
      'icon': Icons.science_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
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
                    'Exams',
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

              // EXAM SUMMARY
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF091993),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.assignment_outlined,
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
                            'Upcoming Exams',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '4 Examinations',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Next Exam',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          exams.first['date'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // TERM FILTER
              SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: terms.length,
                  itemBuilder: (context, index) {
                    final term = terms[index];
                    final isSelected = selectedTerm == term;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(term),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            selectedTerm = term;
                          });
                        },
                        selectedColor: const Color(0xFF091993),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF2F313D),
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF091993)
                              : Colors.grey.shade300,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // TITLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Exam Schedule',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F313D),
                    ),
                  ),

                  Text(
                    selectedTerm,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // EXAM LIST
              Expanded(
                child: exams.isEmpty
                    ? const Center(
                        child: Text(
                          'No exams scheduled',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: exams.length,
                        itemBuilder: (context, index) {
                          return _examCard(exams[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _examCard(Map<String, dynamic> exam) {
    final Color color = exam['color'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // DATE
              Container(
                width: 58,
                height: 65,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      exam['date'].toString().split(' ')[1].replaceAll(',', ''),
                      style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      exam['date'].toString().split(' ')[0],
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 13),

              // SUBJECT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam['subject'],
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F313D),
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      exam['day'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  exam['status'],
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          const Divider(),

          const SizedBox(height: 8),

          // EXAM DETAILS
          Row(
            children: [
              Icon(
                Icons.access_time_outlined,
                size: 16,
                color: Colors.grey.shade500,
              ),

              const SizedBox(width: 6),

              Expanded(
                child: Text(
                  exam['time'],
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                  ),
                ),
              ),

              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey.shade500,
              ),

              const SizedBox(width: 5),

              Text(
                exam['venue'],
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Icon(
                Icons.category_outlined,
                size: 16,
                color: Colors.grey.shade500,
              ),

              const SizedBox(width: 6),

              Text(
                exam['type'],
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                ),
              ),

              const Spacer(),

              TextButton(
                onPressed: () {
                  // Open exam details page
                },
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    color: Color(0xFF091993),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}