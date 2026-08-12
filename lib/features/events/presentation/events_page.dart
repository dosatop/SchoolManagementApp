import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  int selectedTerm = 0;

  final List<String> terms = [
    'First Term',
    'Second Term',
    'Third Term',
  ];

  final List<Map<String, dynamic>> events = [
    // =========================
    // FIRST TERM
    // =========================
    {
      'term': 'First Term',
      'title': 'Resumption Day',
      'date': 'Sep 8, 2026',
      'day': 'Tuesday',
      'time': '8:00 AM',
      'venue': 'School Assembly Ground',
      'category': 'School',
      'description':
          'Students resume for the new academic session. All students are expected to report to school on time.',
      'color': Color(0xFF091993),
      'icon': Icons.school_outlined,
    },
    {
      'term': 'First Term',
      'title': 'Parents Teachers Meeting',
      'date': 'Sep 26, 2026',
      'day': 'Saturday',
      'time': '10:00 AM',
      'venue': 'School Hall',
      'category': 'Meeting',
      'description':
          'Parents and teachers meet to discuss student progress, academic performance and school activities.',
      'color': Colors.orange,
      'icon': Icons.groups_outlined,
    },
    {
      'term': 'First Term',
      'title': 'Inter-House Sports',
      'date': 'Oct 16, 2026',
      'day': 'Friday',
      'time': '9:00 AM',
      'venue': 'School Sports Field',
      'category': 'Sports',
      'description':
          'Annual inter-house sporting activities featuring track events, field events and team competitions.',
      'color': Colors.green,
      'icon': Icons.sports_soccer_outlined,
    },
    {
      'term': 'First Term',
      'title': 'Mid-Term Break',
      'date': 'Oct 29, 2026',
      'day': 'Thursday',
      'time': '12:00 PM',
      'venue': 'School',
      'category': 'Holiday',
      'description':
          'Students begin the scheduled mid-term break and return according to the school calendar.',
      'color': Colors.purple,
      'icon': Icons.beach_access_outlined,
    },
    {
      'term': 'First Term',
      'title': 'First Term Examination',
      'date': 'Nov 30, 2026',
      'day': 'Monday',
      'time': '8:00 AM',
      'venue': 'Examination Halls',
      'category': 'Academic',
      'description':
          'First term examinations begin. Students should arrive early and come prepared with the required examination materials.',
      'color': Colors.red,
      'icon': Icons.assignment_outlined,
    },

    // =========================
    // SECOND TERM
    // =========================
    {
      'term': 'Second Term',
      'title': 'Second Term Resumption',
      'date': 'Jan 11, 2027',
      'day': 'Monday',
      'time': '8:00 AM',
      'venue': 'School Assembly Ground',
      'category': 'School',
      'description':
          'Students resume for the second term of the academic session.',
      'color': Color(0xFF091993),
      'icon': Icons.school_outlined,
    },
    {
      'term': 'Second Term',
      'title': 'Career Day',
      'date': 'Feb 5, 2027',
      'day': 'Friday',
      'time': '10:00 AM',
      'venue': 'School Hall',
      'category': 'Career',
      'description':
          'Students interact with professionals from different fields and learn about career opportunities and future study options.',
      'color': Colors.blue,
      'icon': Icons.work_outline,
    },
    {
      'term': 'Second Term',
      'title': 'Cultural Day',
      'date': 'Feb 19, 2027',
      'day': 'Friday',
      'time': '9:00 AM',
      'venue': 'School Auditorium',
      'category': 'Cultural',
      'description':
          'A celebration of culture featuring traditional clothing, food, music, dance and presentations.',
      'color': Colors.teal,
      'icon': Icons.celebration_outlined,
    },
    {
      'term': 'Second Term',
      'title': 'Second Term Examination',
      'date': 'Mar 22, 2027',
      'day': 'Monday',
      'time': '8:00 AM',
      'venue': 'Examination Halls',
      'category': 'Academic',
      'description':
          'Second term examinations begin for all students.',
      'color': Colors.red,
      'icon': Icons.assignment_outlined,
    },

    // =========================
    // THIRD TERM
    // =========================
    {
      'term': 'Third Term',
      'title': 'Third Term Resumption',
      'date': 'Apr 19, 2027',
      'day': 'Monday',
      'time': '8:00 AM',
      'venue': 'School Assembly Ground',
      'category': 'School',
      'description':
          'Students resume for the final term of the academic session.',
      'color': Color(0xFF091993),
      'icon': Icons.school_outlined,
    },
    {
      'term': 'Third Term',
      'title': 'Science Fair',
      'date': 'May 14, 2027',
      'day': 'Friday',
      'time': '10:00 AM',
      'venue': 'School Hall',
      'category': 'Academic',
      'description':
          'Students showcase science projects, experiments and innovative ideas.',
      'color': Colors.green,
      'icon': Icons.science_outlined,
    },
    {
      'term': 'Third Term',
      'title': 'Graduation Ceremony',
      'date': 'Jun 25, 2027',
      'day': 'Friday',
      'time': '10:00 AM',
      'venue': 'School Auditorium',
      'category': 'Ceremony',
      'description':
          'Graduation ceremony celebrating students completing their programme.',
      'color': Colors.purple,
      'icon': Icons.workspace_premium_outlined,
    },
    {
      'term': 'Third Term',
      'title': 'Final Examinations',
      'date': 'Jul 5, 2027',
      'day': 'Monday',
      'time': '8:00 AM',
      'venue': 'Examination Halls',
      'category': 'Academic',
      'description':
          'Final examinations for the academic session begin.',
      'color': Colors.red,
      'icon': Icons.menu_book_outlined,
    },
    {
      'term': 'Third Term',
      'title': 'End of Session',
      'date': 'Jul 23, 2027',
      'day': 'Friday',
      'time': '12:00 PM',
      'venue': 'School',
      'category': 'School',
      'description':
          'The academic session officially comes to an end.',
      'color': Colors.orange,
      'icon': Icons.flag_outlined,
    },
  ];

  List<Map<String, dynamic>> get filteredEvents {
    return events
        .where((event) => event['term'] == terms[selectedTerm])
        .toList();
  }

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

              // =========================
              // HEADER
              // =========================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackButton(),

                  const Text(
                    'School Events',
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

              // =========================
              // SESSION SUMMARY
              // =========================
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
                        Icons.event_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 15),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Academic Session',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '2026 / 2027',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      '${events.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =========================
              // TERM SELECTOR
              // =========================
              SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: terms.length,
                  itemBuilder: (context, index) {
                    final selected = selectedTerm == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedTerm = index;
                        });
                      },
                      child: Container(
                        margin:
                            const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF091993)
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(25),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFF091993)
                                : Colors.grey.shade300,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          terms[index],
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : const Color(0xFF2F313D),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // =========================
              // TERM TITLE
              // =========================
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    terms[selectedTerm],
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F313D),
                    ),
                  ),

                  Text(
                    '${filteredEvents.length} Events',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // =========================
              // EVENT LIST
              // =========================
              Expanded(
                child: ListView.builder(
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];

                    return _eventCard(
                      context,
                      event,
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

  Widget _eventCard(
    BuildContext context,
    Map<String, dynamic> event,
  ) {
    final Color color = event['color'];

    return GestureDetector(
      onTap: () {
        context.push(
          '/events/${event['title']}',
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // DATE
            Container(
              width: 55,
              padding: const EdgeInsets.symmetric(
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    event['date'].toString().split(' ')[1]
                        .replaceAll(',', ''),
                    style: TextStyle(
                      color: color,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    event['date']
                        .toString()
                        .split(' ')[0],
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // EVENT ICON
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                event['icon'],
                color: color,
                size: 23,
              ),
            ),

            const SizedBox(width: 12),

            // DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F313D),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Row(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event['time'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event['venue'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
