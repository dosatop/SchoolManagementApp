import 'package:flutter/material.dart';

class AssignmentViewPage extends StatefulWidget {
  final String assignmentId;

  const AssignmentViewPage({super.key, required this.assignmentId});

  @override
  State<AssignmentViewPage> createState() => _AssignmentViewPageState();
}

class _AssignmentViewPageState extends State<AssignmentViewPage> {
  bool isSubmitting = false;

  // --------------------------------------------------
  // TEMPORARY DATA
  // Replace this with your API/repository later.
  // --------------------------------------------------

  final List<Map<String, dynamic>> assignments = [
    {
      'id': '1',
      'subject': 'Mathematics',
      'title': 'Algebra Assignment',
      'dueDate': '20 August, 2026',
      'description':
          'Complete the algebra questions provided by your mathematics teacher.',
      'status': 'Pending',
    },
    {
      'id': '2',
      'subject': 'English',
      'title': 'Essay Writing',
      'dueDate': '22 August, 2026',
      'description':
          'Write an essay about the importance of education in modern society.',
      'status': 'Submitted',
    },
    {
      'id': '3',
      'subject': 'Biology',
      'title': 'Human Digestive System',
      'dueDate': '10 August, 2026',
      'description':
          'Explain the major organs involved in the human digestive system.',
      'status': 'Overdue',
    },
  ];

  Map<String, dynamic>? get assignment {
    try {
      return assignments.firstWhere(
        (item) => item['id'].toString() == widget.assignmentId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAssignment = assignment;

    // Assignment doesn't exist
    if (currentAssignment == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(title: const Text('Assignment')),
        body: const Center(
          child: Text(
            'Assignment not found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    final String subject = currentAssignment['subject'];
    final String title = currentAssignment['title'];
    final String dueDate = currentAssignment['dueDate'];
    final String description = currentAssignment['description'];
    final String status = currentAssignment['status'];

    final isSubmitted = status.toLowerCase() == 'submitted';
    final isOverdue = status.toLowerCase() == 'overdue';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackButton(),

                  const Text(
                    'Assignment',
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
                      Icons.more_vert,
                      size: 28,
                      color: Color(0xFF2F313D),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ASSIGNMENT HEADER
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
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.menu_book_outlined,
                                  color: Colors.white,
                                  size: 27,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Text(
                                  subject,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              _statusBadge(status),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: Colors.white70,
                                size: 17,
                              ),

                              const SizedBox(width: 7),

                              Text(
                                'Due $dueDate',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // DESCRIPTION
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F313D),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // INSTRUCTIONS
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F313D),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _instruction(
                      number: '1',
                      text:
                          'Complete all the questions given in the assignment.',
                    ),

                    _instruction(
                      number: '2',
                      text: 'Make sure your answers are clearly written.',
                    ),

                    _instruction(
                      number: '3',
                      text: 'Submit your assignment before the due date.',
                    ),

                    _instruction(
                      number: '4',
                      text: 'Upload your work as a PDF or image.',
                    ),

                    const SizedBox(height: 25),

                    // ATTACHMENT
                    const Text(
                      'Attachment',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F313D),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_outlined,
                              color: Colors.red,
                            ),
                          ),

                          const SizedBox(width: 12),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Assignment_Questions.pdf',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),

                                SizedBox(height: 4),

                                Text(
                                  '2.4 MB',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          IconButton(
                            onPressed: () {
                              // Download attachment
                            },
                            icon: const Icon(
                              Icons.download_outlined,
                              color: Color(0xFF091993),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // SUBMISSION
                    if (isSubmitted)
                      _submittedCard()
                    else if (isOverdue)
                      _overdueCard()
                    else
                      _submissionCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // STATUS BADGE
  // --------------------------------------------------

  Widget _statusBadge(String status) {
    late Color background;

    switch (status.toLowerCase()) {
      case 'submitted':
        background = Colors.green;
        break;

      case 'overdue':
        background = Colors.red;
        break;

      default:
        background = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --------------------------------------------------
  // INSTRUCTION
  // --------------------------------------------------

  Widget _instruction({required String number, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF091993).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: Color(0xFF091993),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // NOT SUBMITTED
  // --------------------------------------------------

  Widget _submissionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Submission',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2F313D),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'You have not submitted this assignment yet.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),

          const SizedBox(height: 15),

          OutlinedButton.icon(
            onPressed: () {
              // Pick file
            },
            icon: const Icon(Icons.attach_file),
            label: const Text('Attach File'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF091993),
              side: const BorderSide(color: Color(0xFF091993)),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: isSubmitting
                ? null
                : () async {
                    setState(() {
                      isSubmitting = true;
                    });

                    await Future.delayed(const Duration(seconds: 2));

                    if (!mounted) return;

                    setState(() {
                      isSubmitting = false;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Assignment submitted successfully'),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF091993),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Submit Assignment',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // SUBMITTED
  // --------------------------------------------------

  Widget _submittedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 30),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assignment Submitted',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.green,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Your assignment has been submitted successfully.',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // OVERDUE
  // --------------------------------------------------

  Widget _overdueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),

          SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assignment Overdue',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: Colors.red,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'The due date for this assignment has passed.',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
