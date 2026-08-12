import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultImportPage extends StatefulWidget {
  const ResultImportPage({super.key});

  @override
  State<ResultImportPage> createState() => _ResultImportPageState();
}

class _ResultImportPageState extends State<ResultImportPage> {
  static const primaryColor = Color(0xFF091993);

  String? selectedClass;
  String? selectedSubject;
  String? selectedExam;

  String? selectedFileName;

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

  bool get canContinue {
    return selectedClass != null &&
        selectedSubject != null &&
        selectedExam != null &&
        selectedFileName != null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(
          color: Color(0xFF2F313D),
        ),
        title: const Text(
          'Import Results',
          style: TextStyle(
            color: Color(0xFF2F313D),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 25),

              const Text(
                'Result Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F313D),
                ),
              ),

              const SizedBox(height: 15),

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

              const SizedBox(height: 18),

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

              const SizedBox(height: 18),

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

              const SizedBox(height: 28),

              const Text(
                'Upload File',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F313D),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Upload an Excel or CSV file containing the student results.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 15),

              _buildUploadBox(),

              const SizedBox(height: 20),

              _buildTemplateCard(),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: canContinue
                      ? () {
                          context.push(
                            '/result-import-preview',
                            extra: {
                              'selectedClass': selectedClass!,
                              'selectedSubject': selectedSubject!,
                              'selectedExam': selectedExam!,
                              'fileName': selectedFileName!,
                            },
                          );
                        }
                      : null,
                  icon: const Icon(Icons.preview_outlined),
                  label: const Text(
                    'Preview Results',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
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
            ],
          ),
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
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.upload_file_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import Multiple Results',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Upload results for an entire class at once',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
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

  Widget _buildUploadBox() {
    final hasFile = selectedFileName != null;

    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 28,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasFile
                ? primaryColor
                : Colors.grey.shade300,
            width: hasFile ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              hasFile
                  ? Icons.description_outlined
                  : Icons.cloud_upload_outlined,
              size: 45,
              color: primaryColor,
            ),

            const SizedBox(height: 12),

            Text(
              hasFile
                  ? selectedFileName!
                  : 'Tap to select a file',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F313D),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              hasFile
                  ? 'File selected successfully'
                  : 'Excel (.xlsx) or CSV (.csv)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),

            if (hasFile) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _pickFile,
                child: const Text(
                  'Change file',
                  style: TextStyle(
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.15),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: primaryColor,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Use the correct format',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F313D),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Your file should contain Student Name, '
                  'Student ID and Score.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Future<void> _pickFile() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['xlsx', 'csv'],
  );

  if (result == null) return;

  setState(() {
    selectedFileName = result.files.single.name;
  });
}
}