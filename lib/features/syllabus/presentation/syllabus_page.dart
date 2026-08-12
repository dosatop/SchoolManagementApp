import 'package:flutter/material.dart';

class SyllabusPage extends StatefulWidget {
  const SyllabusPage({super.key});

  @override
  State<SyllabusPage> createState() => _SyllabusPageState();
}

class _SyllabusPageState extends State<SyllabusPage> {
  String selectedTerm = 'First Term';

  final List<String> terms = [
    'First Term',
    'Second Term',
    'Third Term',
  ];

  final List<Map<String, dynamic>> syllabus = [
    {
      'subject': 'Mathematics',
      'teacher': 'Mr. Anderson',
      'progress': 0.72,
      'color': const Color(0xFF091993),
      'icon': Icons.calculate_outlined,
      'topics': [
        'Algebra',
        'Linear Equations',
        'Quadratic Equations',
        'Indices and Logarithms',
        'Geometry',
        'Statistics',
      ],
    },
    {
      'subject': 'English',
      'teacher': 'Mrs. Williams',
      'progress': 0.58,
      'color': Colors.orange,
      'icon': Icons.menu_book_outlined,
      'topics': [
        'Grammar',
        'Comprehension',
        'Essay Writing',
        'Letter Writing',
        'Literature',
        'Vocabulary Development',
      ],
    },
    {
      'subject': 'Biology',
      'teacher': 'Dr. Johnson',
      'progress': 0.64,
      'color': Colors.green,
      'icon': Icons.biotech_outlined,
      'topics': [
        'Cell Structure',
        'Nutrition',
        'Human Digestive System',
        'Respiration',
        'Transport System',
        'Ecology',
      ],
    },
    {
      'subject': 'Physics',
      'teacher': 'Mr. Smith',
      'progress': 0.45,
      'color': Colors.purple,
      'icon': Icons.science_outlined,
      'topics': [
        'Measurement',
        'Motion',
        'Forces',
        'Energy',
        'Waves',
        'Electricity',
      ],
    },
    {
      'subject': 'Chemistry',
      'teacher': 'Mrs. Davis',
      'progress': 0.51,
      'color': Colors.red,
      'icon': Icons.science_outlined,
      'topics': [
        'Matter',
        'Atomic Structure',
        'Periodic Table',
        'Chemical Bonding',
        'Acids and Bases',
        'Chemical Reactions',
      ],
    },
  ];

  double get overallProgress {
    if (syllabus.isEmpty) return 0;

    final total = syllabus.fold<double>(
      0,
      (sum, subject) => sum + subject['progress'],
    );

    return total / syllabus.length;
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

              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackButton(),

                  const Text(
                    'Syllabus',
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

              // OVERALL PROGRESS CARD
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
                    const Row(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Academic Syllabus',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Overall Progress',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),

                        Text(
                          '${(overallProgress * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: overallProgress,
                        minHeight: 9,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      '${syllabus.length} subjects • $selectedTerm',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // TERM SELECTOR
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

              const SizedBox(height: 18),

              // SUBJECTS TITLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subjects',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F313D),
                    ),
                  ),

                  Text(
                    '${syllabus.length} Subjects',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // SUBJECT LIST
              Expanded(
                child: ListView.builder(
                  itemCount: syllabus.length,
                  itemBuilder: (context, index) {
                    return _syllabusCard(syllabus[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _syllabusCard(Map<String, dynamic> subject) {
    final Color color = subject['color'];
    final double progress = subject['progress'];
    final List<String> topics =
        List<String>.from(subject['topics']);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 5,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            15,
            0,
            15,
            15,
          ),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              subject['icon'],
              color: color,
              size: 25,
            ),
          ),
          title: Text(
            subject['subject'],
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F313D),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              subject['teacher'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Course Progress',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),

            const SizedBox(height: 18),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Topics',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F313D),
                ),
              ),
            ),

            const SizedBox(height: 10),

            ...topics.asMap().entries.map(
              (entry) {
                final topicIndex = entry.key;
                final topic = entry.value;

                final completed =
                    topicIndex <
                    (topics.length * progress).round();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    children: [
                      Icon(
                        completed
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: completed
                            ? Colors.green
                            : Colors.grey.shade400,
                      ),

                      const SizedBox(width: 9),

                      Expanded(
                        child: Text(
                          topic,
                          style: TextStyle(
                            fontSize: 13,
                            color: completed
                                ? Colors.grey.shade700
                                : const Color(0xFF2F313D),
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}