import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultSetupPage extends StatefulWidget {
  const ResultSetupPage({super.key});

  @override
  State<ResultSetupPage> createState() => _ResultSetupPageState();
}

class _ResultSetupPageState extends State<ResultSetupPage> {
  static const primaryColor = Color(0xFF091993);

  String? selectedClass;
  String? selectedSubject;
  String? selectedExam;

  final classes = [
    'JSS 1',
    'JSS 2',
    'JSS 3',
    'SS 1',
    'SS 2',
    'SS 3',
  ];

  final subjects = [
    'Mathematics',
    'English',
    'Physics',
    'Biology',
    'Chemistry',
  ];

  final exams = [
    '1st Term',
    '2nd Term',
    '3rd Term',
    'Mid-Term',
    'Final Examination',
  ];

  @override
  Widget build(BuildContext context) {
    final canContinue =
        selectedClass != null &&
        selectedSubject != null &&
        selectedExam != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(
          color: Color(0xFF2F313D),
        ),
        title: const Text(
          'Result Setup',
          style: TextStyle(
            color: Color(0xFF2F313D),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.assessment_outlined,
                    color: Colors.white,
                    size: 35,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Set Up Result Entry',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Select the class, subject and examination before entering results.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            _buildLabel('Class'),

            _buildDropdown(
              value: selectedClass,
              hint: 'Select class',
              items: classes,
              onChanged: (value) {
                setState(() {
                  selectedClass = value;
                });
              },
            ),

            const SizedBox(height: 20),

            _buildLabel('Subject'),

            _buildDropdown(
              value: selectedSubject,
              hint: 'Select subject',
              items: subjects,
              onChanged: (value) {
                setState(() {
                  selectedSubject = value;
                });
              },
            ),

            const SizedBox(height: 20),

            _buildLabel('Examination'),

            _buildDropdown(
              value: selectedExam,
              hint: 'Select examination',
              items: exams,
              onChanged: (value) {
                setState(() {
                  selectedExam = value;
                });
              },
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: canContinue
                    ? () {
                        context.push(
                          '/result-entry',
                          extra: {
                            'selectedClass': selectedClass!,
                            'selectedSubject': selectedSubject!,
                            'selectedExam': selectedExam!,
                          },
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Continue to Result Entry',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2F313D),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: primaryColor,
          ),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}