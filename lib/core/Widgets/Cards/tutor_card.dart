import 'package:app/features/tutor/models/tutor_model.dart';
import 'package:flutter/material.dart';

class TutorCard extends StatelessWidget {
  final TutorModel tutor;
  final VoidCallback? onTap;

  const TutorCard({
    super.key,
    required this.tutor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Your existing tutor UI here
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: tutor.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.person,
                  size: 55,
                  color: Color(0xFF091993),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              tutor.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F313D),
              ),
            ),

            const SizedBox(height: 4),

            Text(
              tutor.subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.star,
                  size: 15,
                  color: Colors.amber,
                ),
                const SizedBox(width: 4),
                Text(
                  tutor.rating.toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Color(0xFF091993),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}