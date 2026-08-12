import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultImportPreviewPage extends StatefulWidget {
  final String selectedClass;
  final String selectedSubject;
  final String selectedExam;
  final String fileName;

  const ResultImportPreviewPage({
    super.key,
    required this.selectedClass,
    required this.selectedSubject,
    required this.selectedExam,
    required this.fileName,
  });

  @override
  State<ResultImportPreviewPage> createState() =>
      _ResultImportPreviewPageState();
}

class _ResultImportPreviewPageState extends State<ResultImportPreviewPage> {
  static const primaryColor = Color(0xFF091993);

  // Temporary sample data.
  // Later this will come from the Excel/CSV file.
  final List<Map<String, dynamic>> students = [
    {'name': 'John Doe', 'id': 'ST001', 'score': 78},
    {'name': 'Mary Jane', 'id': 'ST002', 'score': 65},
    {'name': 'David Smith', 'id': 'ST003', 'score': 42},
    {'name': 'Sarah Williams', 'id': 'ST004', 'score': 89},
    {'name': 'Michael Johnson', 'id': 'ST005', 'score': 55},
  ];

  bool get hasInvalidScores {
    return students.any((student) {
      final score = student['score'] as int;
      return score < 0 || score > 100;
    });
  }

  String getGrade(int score) {
    if (score >= 70) return 'A';
    if (score >= 60) return 'B';
    if (score >= 50) return 'C';
    if (score >= 45) return 'D';
    if (score >= 40) return 'E';
    return 'F';
  }

  Color getGradeColor(int score) {
    if (score >= 70) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 50) return Colors.orange;
    if (score >= 40) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF2F313D)),
        title: const Text(
          'Preview Results',
          style: TextStyle(
            color: Color(0xFF2F313D),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 5, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),

                    const SizedBox(height: 20),

                    _buildFileCard(),

                    const SizedBox(height: 20),

                    _buildSummary(),

                    const SizedBox(height: 25),

                    const Text(
                      'Student Results',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F313D),
                      ),
                    ),

                    const SizedBox(height: 10),

                    _buildResultsTable(),

                    const SizedBox(height: 20),

                    if (hasInvalidScores) _buildErrorMessage(),

                    const SizedBox(height: 10),

                    _buildNotice(),
                  ],
                ),
              ),
            ),

            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.preview_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review Imported Results',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 5),
                Text(
                  '${widget.selectedSubject} • ${widget.selectedClass}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.selectedExam,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.table_chart_outlined, color: Colors.green),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Imported File',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.fileName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F313D),
                  ),
                ),
              ],
            ),
          ),

          const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final totalStudents = students.length;

    final totalScore = students.fold<int>(
      0,
      (sum, student) => sum + (student['score'] as int),
    );

    final average = totalStudents == 0 ? 0 : totalScore / totalStudents;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.people_outline,
            title: 'Students',
            value: '$totalStudents',
            color: primaryColor,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _SummaryCard(
            icon: Icons.analytics_outlined,
            title: 'Average',
            value: average.toStringAsFixed(1),
            color: Colors.orange,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _SummaryCard(
            icon: Icons.check_circle_outline,
            title: 'Status',
            value: hasInvalidScores ? 'Error' : 'Valid',
            color: hasInvalidScores ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildResultsTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              primaryColor.withOpacity(0.06),
            ),
            columnSpacing: 25,
            horizontalMargin: 15,
            columns: const [
              DataColumn(
                label: Text(
                  'Student',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'ID',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                numeric: true,
                label: Text(
                  'Score',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'Grade',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: students.map((student) {
              final score = student['score'] as int;
              final grade = getGrade(score);
              final gradeColor = getGradeColor(score);

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      student['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2F313D),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      student['id'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      '$score',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: gradeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        grade,
                        style: TextStyle(
                          color: gradeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Some scores are invalid. Please correct the file and import it again.',
              style: TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'After submission, these results will be sent to the administrator for review and approval before they are published to students and parents.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: hasInvalidScores ? null : _submitForReview,
          icon: const Icon(Icons.send_outlined),
          label: const Text(
            'Submit for Admin Review',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            disabledBackgroundColor: Colors.grey.shade300,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
    );
  }

  void _submitForReview() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Submit Results?'),
          content: const Text(
            'These results will be sent to the administrator for review. They will not be visible to students or parents until approved and published.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Results submitted for admin review.'),
                    backgroundColor: Colors.green,
                  ),
                );

                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F313D),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
