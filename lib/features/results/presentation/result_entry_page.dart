import 'package:app/features/results/models/student_result_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultEntryPage extends StatefulWidget {
  final String selectedClass;
  final String selectedSubject;
  final String selectedExam;

  const ResultEntryPage({
    super.key,
    required this.selectedClass,
    required this.selectedSubject,
    required this.selectedExam,
  });

  @override
  State<ResultEntryPage> createState() => _ResultEntryPageState();
}

class _ResultEntryPageState extends State<ResultEntryPage> {
  final List<StudentResultModel> students = [
    StudentResultModel(
      studentId: '1',
      studentName: 'John Doe',
      studentClass: 'JSS 1A',
    ),
    StudentResultModel(
      studentId: '2',
      studentName: 'Mary Jane',
      studentClass: 'JSS 1A',
    ),
    StudentResultModel(
      studentId: '3',
      studentName: 'David Smith',
      studentClass: 'JSS 1A',
    ),
    StudentResultModel(
      studentId: '4',
      studentName: 'Sarah Williams',
      studentClass: 'JSS 1A',
    ),
    StudentResultModel(
      studentId: '5',
      studentName: 'Michael Johnson',
      studentClass: 'JSS 1A',
    ),
  ];

  final Map<String, TextEditingController> caControllers = {};
  final Map<String, TextEditingController> examControllers = {};

  @override
  void initState() {
    super.initState();

    for (final student in students) {
      caControllers[student.studentId] = TextEditingController();

      examControllers[student.studentId] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in caControllers.values) {
      controller.dispose();
    }

    for (final controller in examControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

  void updateScore(
    StudentResultModel student,
    TextEditingController controller,
    bool isCa,
  ) {
    final value = double.tryParse(controller.text) ?? 0;

    setState(() {
      if (isCa) {
        student.caScore = value;
      } else {
        student.examScore = value;
      }
    });
  }

  void previewResults() {
    // We'll connect this to the preview page next.
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Results Ready'),
          content: const Text(
            'The results have been entered successfully. '
            'Next we will add the preview and submit functionality.',
          ),
          actions: [
            TextButton(
              onPressed: () => context.push(
                '/result-preview',
                extra: {
                  'selectedClass': widget.selectedClass,
                  'selectedSubject': widget.selectedSubject,
                  'selectedExam': widget.selectedExam,
                  'students': students,
                },
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(onPressed: () => context.pop(), child: Text("Back")),
                  const Text('OK'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),

      appBar: AppBar(
        title: const Text('Enter Results'),
        backgroundColor: const Color(0xFF091993),
        foregroundColor: Colors.white,
      ),

      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedClass,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${widget.selectedSubject} • ${widget.selectedExam}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];

                return _studentCard(student);
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: previewResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF091993),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Preview Results',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentCard(StudentResultModel student) {
    final caController = caControllers[student.studentId]!;
    final examController = examControllers[student.studentId]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            student.studentName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F313D),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _scoreField(
                  label: 'CA / 40',
                  controller: caController,
                  onChanged: () {
                    updateScore(student, caController, true);
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: _scoreField(
                  label: 'Exam / 60',
                  controller: examController,
                  onChanged: () {
                    updateScore(student, examController, false);
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: TextStyle(color: Colors.grey.shade600)),
              Text(
                '${student.total.toStringAsFixed(0)} / 100',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF091993),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scoreField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
