import 'package:app/features/results/presentation/result_entry_page.dart';
import 'package:flutter/material.dart';

class ResultUploadPage extends StatefulWidget {
  const ResultUploadPage({super.key});

  @override
  State<ResultUploadPage> createState() => _ResultUploadPageState();
}

class _ResultUploadPageState extends State<ResultUploadPage> {
  String? selectedClass;
  String? selectedSubject;
  String? selectedExam;

  final classes = [
    'JSS 1A',
    'JSS 1B',
    'JSS 2A',
    'JSS 2B',
    'JSS 3A',
    'JSS 3B',
  ];

  final subjects = [
    'Mathematics',
    'English',
    'Physics',
    'Biology',
    'Chemistry',
  ];

  final exams = [
    'First Term Examination',
    'Second Term Examination',
    'Third Term Examination',
  ];

  void continueToResults() {
    if (selectedClass == null ||
        selectedSubject == null ||
        selectedExam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select class, subject and examination'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultEntryPage(
          selectedClass: selectedClass!,
          selectedSubject: selectedSubject!,
          selectedExam: selectedExam!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text('Upload Results'),
        backgroundColor: const Color(0xFF091993),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Student Results',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F313D),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Select the class, subject and examination before entering results.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 30),

            _buildDropdown(
              label: 'Class',
              value: selectedClass,
              items: classes,
              onChanged: (value) {
                setState(() {
                  selectedClass = value;
                });
              },
            ),

            const SizedBox(height: 20),

            _buildDropdown(
              label: 'Subject',
              value: selectedSubject,
              items: subjects,
              onChanged: (value) {
                setState(() {
                  selectedSubject = value;
                });
              },
            ),

            const SizedBox(height: 20),

            _buildDropdown(
              label: 'Examination',
              value: selectedExam,
              items: exams,
              onChanged: (value) {
                setState(() {
                  selectedExam = value;
                });
              },
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: continueToResults,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF091993),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2F313D),
          ),
        ),

        const SizedBox(height: 8),

        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade200,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.grey.shade200,
              ),
            ),
          ),
          hint: Text('Select $label'),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}