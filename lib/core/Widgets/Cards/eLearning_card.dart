import 'package:app/core/Models/e_learning.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ELearningCard extends StatelessWidget {
  final ELearning tile;

  const ELearningCard({super.key, required this.tile});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push(tile.route);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // IMAGE
            Container(
              width: 85,
              height: 85,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF091993).withOpacity(0.07),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Image.asset(
                tile.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.menu_book_outlined,
                    size: 38,
                    color: Color(0xFF091993),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // TITLE
            Text(
              tile.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.2,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F313D),
              ),
            ),

            const SizedBox(height: 6),

            // OPEN
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Open',
                  style: TextStyle(
                    color: Color(0xFF091993),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 10,
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