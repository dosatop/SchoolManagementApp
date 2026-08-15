import 'package:app/features/Subjects/models/subject_model.dart';
import 'package:app/features/Subjects/presentation/create_subject_page.dart';
import 'package:app/features/Subjects/provider/subjects_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubjectsPage extends ConsumerWidget {
  final String schoolId;
  final String schoolName;

  const SubjectsPage({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subjectsProvider(schoolId));

    return Scaffold(
      backgroundColor: background,

      // =============================================================
      // APP BAR
      // =============================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 20,

        title: const Text(
          'Subjects',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(subjectsProvider(schoolId));
            },

            icon: const Icon(Icons.refresh_rounded, color: textDark),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // =============================================================
      // BODY
      // =============================================================
      body: SafeArea(
        child: state.when(
          // ---------------------------------------------------------
          // LOADING
          // ---------------------------------------------------------
          loading: () =>
              const Center(child: CircularProgressIndicator(color: primary)),

          // ---------------------------------------------------------
          // ERROR
          // ---------------------------------------------------------
          error: (error, stackTrace) {
            return _errorState(context, ref, error);
          },

          // ---------------------------------------------------------
          // DATA
          // ---------------------------------------------------------
          data: (subjects) {
            return RefreshIndicator(
              color: primary,

              onRefresh: () async {
                ref.invalidate(subjectsProvider(schoolId));

                await ref.read(subjectsProvider(schoolId).future);
              },

              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),

                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),

                children: [
                  // =================================================
                  // SCHOOL HEADER
                  // =================================================
                  _schoolHeader(subjects.length),

                  const SizedBox(height: 25),

                  const Text(
                    'Subjects',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Manage subjects offered by $schoolName.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),

                  const SizedBox(height: 15),

                  if (subjects.isEmpty)
                    _emptyState()
                  else
                    ...subjects.map((subject) => _subjectCard(subject)),
                ],
              ),
            );
          },
        ),
      ),

      // =============================================================
      // ADD SUBJECT BUTTON
      // =============================================================
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 5,

        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CreateSubjectPage(schoolId: schoolId, schoolName: schoolName),
            ),
          );

          // Refresh subjects after successful creation.
          if (created == true) {
            ref.invalidate(subjectsProvider(schoolId));
          }
        },

        icon: const Icon(Icons.add_rounded),

        label: const Text(
          'Add Subject',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ================================================================
  // SCHOOL HEADER
  // ================================================================

  Widget _schoolHeader(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, Color(0xFF2638C4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(23),

        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.13),
              borderRadius: BorderRadius.circular(17),
            ),

            child: const Icon(
              Icons.menu_book_outlined,
              color: Colors.white,
              size: 31,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  schoolName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Academic subjects',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              borderRadius: BorderRadius.circular(15),
            ),

            child: Column(
              children: [
                Text(
                  '$count',

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Text(
                  'Subjects',
                  style: TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SUBJECT CARD
  // ================================================================

  Widget _subjectCard(SubjectModel subject) {
    final name = subject.name.trim();

    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Padding(
        padding: const EdgeInsets.all(15),

        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,

              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),

              child: Center(
                child: Text(
                  initial,

                  style: const TextStyle(
                    color: primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    name.isEmpty ? 'Unnamed Subject' : name,

                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  if (subject.code != null && subject.code!.isNotEmpty) ...[
                    const SizedBox(height: 5),

                    Text(
                      'Code: ${subject.code}',

                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),

              decoration: BoxDecoration(
                color: primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),

              child: const Text(
                'SUBJECT',

                style: TextStyle(
                  color: primary,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // EMPTY STATE
  // ================================================================

  Widget _emptyState() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 45),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,

            decoration: BoxDecoration(
              color: primaryLight,
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.menu_book_outlined,
              color: primary,
              size: 35,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'No subjects yet',

            style: TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'No subjects have been added to $schoolName yet.',
            textAlign: TextAlign.center,

            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ERROR STATE
  // ================================================================

  Widget _errorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 55,
            ),

            const SizedBox(height: 15),

            const Text(
              'Unable to load subjects',

              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error.toString(),
              textAlign: TextAlign.center,

              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(subjectsProvider(schoolId));
              },

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('Try Again'),

              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
