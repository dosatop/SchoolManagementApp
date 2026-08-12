import 'package:app/features/assignment/models/assignment_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AssignmentCard extends StatelessWidget {
  final Assignment assignment;

  const AssignmentCard({
    super.key,
    required this.assignment,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = assignment.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // TOP SECTION
            Row(
              children: [
                // Subject icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF091993).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    color: Color(0xFF091993),
                    size: 26,
                  ),
                ),

                const SizedBox(width: 12),

                // Subject + Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.subject,
                        style: const TextStyle(
                          color: Color(0xFF091993),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        assignment.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F313D),
                        ),
                      ),
                    ],
                  ),
                ),

                // STATUS
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    assignment.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // DESCRIPTION
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                assignment.description,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 15),

            const Divider(),

            const SizedBox(height: 5),

            // BOTTOM SECTION
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 17,
                  color: Colors.grey,
                ),

                const SizedBox(width: 7),

                Text(
                  'Due ${assignment.dueDate}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),

                const Spacer(),

                TextButton(
                  onPressed: () {
                    context.push(
                      '/assignments/${assignment.id}',
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF091993),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}