import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultsManagementPage extends StatelessWidget {
  const ResultsManagementPage({super.key});

  static const primaryColor = Color(0xFF091993);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF2F313D)),
        title: const Text(
          'Results Management',
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
                'Enter Results',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F313D),
                ),
              ),

              const SizedBox(height: 12),

              _ActionCard(
                icon: Icons.edit_note_outlined,
                title: 'Enter Results Manually',
                subtitle: 'Enter scores for students one by one.',
                onTap: () {
                  context.push('/result-setup');
                },
              ),

              const SizedBox(height: 12),

              _ActionCard(
                icon: Icons.upload_file_outlined,
                title: 'Import Results',
                subtitle: 'Upload multiple student results using Excel or CSV.',
                onTap: () {
                  context.push('/result-import');
                },
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Submissions',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F313D),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      context.push('/result-submissions');
                    },
                    child: const Text(
                      'View All',
                      style: TextStyle(color: primaryColor),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              _SubmissionCard(
                subject: 'Mathematics',
                className: 'SS2 A',
                term: '2nd Term',
                status: 'Submitted',
                statusColor: Colors.orange,
              ),

              const SizedBox(height: 12),

              _SubmissionCard(
                subject: 'Physics',
                className: 'SS2 A',
                term: '1st Term',
                status: 'Approved',
                statusColor: Colors.green,
              ),

              const SizedBox(height: 12),

              _SubmissionCard(
                subject: 'English',
                className: 'SS1 B',
                term: '2nd Term',
                status: 'Published',
                statusColor: primaryColor,
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
              Icons.assessment_outlined,
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
                  'Manage Student Results',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 5),
                Text(
                  'Enter, review and submit results',
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
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF091993).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: const Color(0xFF091993), size: 27),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2F313D),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios,
                size: 15,
                color: Color(0xFF091993),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final String subject;
  final String className;
  final String term;
  final String status;
  final Color statusColor;

  const _SubmissionCard({
    required this.subject,
    required this.className,
    required this.term,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: Color(0xFF091993)),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F313D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$className • $term',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
