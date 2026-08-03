import 'package:app/Models/academic_tile.dart';
import 'package:flutter/material.dart';

class AcademicCard extends StatelessWidget {
  final AcademicTile tile;

  const AcademicCard({super.key, required this.tile});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              tile.imageUrl,
              width: 50,
              height: 50,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.image_not_supported, size: 50);
              },
            ),

            const SizedBox(height: 8),

            Text(
              tile.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 47, 49, 61),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
