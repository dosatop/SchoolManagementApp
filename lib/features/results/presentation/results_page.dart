import 'package:flutter/material.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  String selectedTerm = 'First Term';

  final List<String> terms = [
    'First Term',
    'Second Term',
    'Third Term',
  ];

  final List<Map<String, dynamic>> results = [
    {
      'subject': 'Mathematics',
      'score': 82,
      'grade': 'A',
      'remark': 'Excellent',
      'color': Colors.green,
      'icon': Icons.calculate_outlined,
    },
    {
      'subject': 'English',
      'score': 76,
      'grade': 'B',
      'remark': 'Very Good',
      'color': Colors.blue,
      'icon': Icons.menu_book_outlined,
    },
    {
      'subject': 'Biology',
      'score': 88,
      'grade': 'A',
      'remark': 'Excellent',
      'color': Colors.green,
      'icon': Icons.biotech_outlined,
    },
    {
      'subject': 'Physics',
      'score': 69,
      'grade': 'B',
      'remark': 'Good',
      'color': Colors.orange,
      'icon': Icons.science_outlined,
    },
    {
      'subject': 'Chemistry',
      'score': 74,
      'grade': 'B',
      'remark': 'Very Good',
      'color': Colors.blue,
      'icon': Icons.science_outlined,
    },
    {
      'subject': 'History',
      'score': 81,
      'grade': 'A',
      'remark': 'Excellent',
      'color': Colors.green,
      'icon': Icons.history_edu_outlined,
    },
    {
      'subject': 'Computer Science',
      'score': 91,
      'grade': 'A',
      'remark': 'Outstanding',
      'color': Colors.green,
      'icon': Icons.computer_outlined,
    },
  ];

  double get averageScore {
    if (results.isEmpty) return 0;

    final total = results.fold<int>(
      0,
      (sum, result) => sum + result['score'] as int,
    );

    return total / results.length;
  }

  int get highestScore {
    if (results.isEmpty) return 0;

    return results
        .map<int>((result) => result['score'] as int)
        .reduce((a, b) => a > b ? a : b);
  }

  int get passedSubjects {
    return results.where((result) {
      return (result['score'] as int) >= 40;
    }).length;
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
                    'Results',
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

              Expanded(
                child: ListView(
                  children: [
                    // SESSION / TERM
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF091993)
                                  .withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.school_outlined,
                              color: Color(0xFF091993),
                            ),
                          ),

                          const SizedBox(width: 12),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Academic Session',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  '2026 / 2027',
                                  style: TextStyle(
                                    color: Color(0xFF2F313D),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedTerm,
                              items: terms.map((term) {
                                return DropdownMenuItem(
                                  value: term,
                                  child: Text(
                                    term,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value == null) return;

                                setState(() {
                                  selectedTerm = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // PERFORMANCE CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF091993),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Overall Performance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.end,
                            children: [
                              Text(
                                averageScore.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const Padding(
                                padding: EdgeInsets.only(
                                  bottom: 7,
                                  left: 5,
                                ),
                                child: Text(
                                  '%',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          const Text(
                            'Average Score',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Expanded(
                                child: _summaryItem(
                                  icon: Icons.emoji_events_outlined,
                                  value: '$highestScore%',
                                  label: 'Highest',
                                ),
                              ),

                              Expanded(
                                child: _summaryItem(
                                  icon: Icons.check_circle_outline,
                                  value: '$passedSubjects',
                                  label: 'Passed',
                                ),
                              ),

                              Expanded(
                                child: _summaryItem(
                                  icon: Icons.menu_book_outlined,
                                  value: '${results.length}',
                                  label: 'Subjects',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // RESULT TITLE
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subject Results',
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

                    const SizedBox(height: 12),

                    // SUBJECT RESULTS
                    ...results.map(
                      (result) => _resultCard(result),
                    ),

                    const SizedBox(height: 20),

                    // DOWNLOAD RESULT
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Download result
                        },
                        icon: const Icon(
                          Icons.download_outlined,
                        ),
                        label: const Text(
                          'Download Result',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              const Color(0xFF091993),
                          side: const BorderSide(
                            color: Color(0xFF091993),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 22,
        ),

        const SizedBox(height: 5),

        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _resultCard(Map<String, dynamic> result) {
    final Color color = result['color'];
    final int score = result['score'];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              result['icon'],
              color: color,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  result['subject'],
                  style: const TextStyle(
                    color: Color(0xFF2F313D),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: score / 100,
                          minHeight: 6,
                          backgroundColor:
                              Colors.grey.shade200,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                            color,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    Text(
                      result['remark'],
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Column(
            children: [
              Text(
                '$score%',
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                result['grade'],
                style: const TextStyle(
                  color: Color(0xFF2F313D),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}