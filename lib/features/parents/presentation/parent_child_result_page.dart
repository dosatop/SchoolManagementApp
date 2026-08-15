import 'package:app/features/parents/models/parent_result_model.dart';
import 'package:app/features/parents/parent_preovider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

class ParentChildResultsPage extends ConsumerWidget {
  final String studentId;
  final String session;
  final String term;

  const ParentChildResultsPage({
    super.key,
    required this.studentId,
    required this.session,
    required this.term,
  });

  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF7F7F7);
  static const Color textDark = Color(0xFF2F313D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (studentId: studentId, session: session, term: term);

    final resultsAsync = ref.watch(parentChildResultsProvider(params));

    return Scaffold(
      backgroundColor: background,

      // ============================================================
      // APP BAR
      // ============================================================
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textDark,
            size: 20,
          ),
        ),

        title: const Text(
          'Academic Results',
          style: TextStyle(
            color: textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================
      body: RefreshIndicator(
        color: primary,

        onRefresh: () async {
          ref.invalidate(parentChildResultsProvider(params));

          await ref.read(parentChildResultsProvider(params).future);
        },

        child: resultsAsync.when(
          // ==========================================================
          // LOADING
          // ==========================================================
          loading: () => _resultsShimmer(),

          // ==========================================================
          // ERROR
          // ==========================================================
          error: (error, stackTrace) {
            return _errorState(error.toString(), ref);
          },

          // ==========================================================
          // DATA
          // ==========================================================
          data: (results) {
            if (results.isEmpty) {
              return _emptyState();
            }

            return _resultsList(results);
          },
        ),
      ),
    );
  }

  // ============================================================
  // RESULTS LIST
  // ============================================================

  Widget _resultsList(List<ParentResultModel> results) {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),

      padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),

      children: [
        _summaryCard(results),

        const SizedBox(height: 25),

        const Text(
          'Results',
          style: TextStyle(
            color: textDark,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        ...results.map((result) => _resultCard(result)),
      ],
    );
  }

  // ============================================================
  // SUMMARY CARD
  // ============================================================

  Widget _summaryCard(List<ParentResultModel> results) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, Color(0xFF1729B8)],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Row(
        children: [
          // Icon
          Container(
            width: 55,
            height: 55,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.school_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 15),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Academic Performance',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),

                const SizedBox(height: 5),

                Text(
                  '$session • $term',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${results.length} Subject${results.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),

                const SizedBox(height: 3),

                const Text(
                  'View your child\'s academic results below.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULT CARD
  // ============================================================

  Widget _resultCard(ParentResultModel result) {
    final grade = _grade(result);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        children: [
          // ========================================================
          // SUBJECT HEADER
          // ========================================================
          Row(
            children: [
              Container(
                width: 45,
                height: 45,

                decoration: BoxDecoration(
                  color: primary.withOpacity(.08),
                  borderRadius: BorderRadius.circular(12),
                ),

                child: const Icon(
                  Icons.menu_book_outlined,
                  color: primary,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _subjectName(result),

                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '$session • $term',

                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,

                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              _gradeBadge(result),
            ],
          ),

          const SizedBox(height: 15),

          Divider(height: 1, color: Colors.grey.shade200),

          const SizedBox(height: 14),

          // ========================================================
          // SCORE DETAILS
          // ========================================================
          Row(
            children: [
              Expanded(
                child: _scoreItem(
                  title: 'Score',
                  value: _score(result),
                  color: primary,
                ),
              ),

              Expanded(
                child: _scoreItem(
                  title: 'Grade',
                  value: grade,
                  color: _gradeColor(grade),
                ),
              ),

              Expanded(
                child: _scoreItem(
                  title: 'Remark',
                  value: _remark(result),
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SCORE ITEM
  // ============================================================

  Widget _scoreItem({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          title,

          style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
        ),

        const SizedBox(height: 5),

        Text(
          value,

          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,

          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // GRADE BADGE
  // ============================================================

  Widget _gradeBadge(ParentResultModel result) {
    final grade = _grade(result);
    final color = _gradeColor(grade);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),

      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(10),
      ),

      child: Text(
        grade,

        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // LOADING SHIMMER
  // ============================================================

  Widget _resultsShimmer() {
    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),

      padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),

      children: [
        // Summary shimmer
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,

          child: Container(
            height: 130,

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),

        const SizedBox(height: 25),

        // Results title shimmer
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,

          child: Container(
            width: 100,
            height: 22,

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Result cards
        ...List.generate(5, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),

            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,

              child: Container(
                height: 145,

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.all(20),

      children: [
        const SizedBox(height: 90),

        Icon(Icons.school_outlined, size: 65, color: Colors.grey.shade400),

        const SizedBox(height: 15),

        const Text(
          'No Results Available',

          textAlign: TextAlign.center,

          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 7),

        Text(
          'There are no academic results available for this child for $term in the $session academic session.',

          textAlign: TextAlign.center,

          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _errorState(String error, WidgetRef ref) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),

      padding: const EdgeInsets.all(20),

      children: [
        const SizedBox(height: 70),

        Icon(Icons.error_outline_rounded, size: 60, color: Colors.red.shade400),

        const SizedBox(height: 15),

        const Text(
          'Unable to Load Results',

          textAlign: TextAlign.center,

          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          error,

          textAlign: TextAlign.center,

          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          '$session • $term',

          textAlign: TextAlign.center,

          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 15),

        Center(
          child: TextButton(
            onPressed: () {
              ref.invalidate(
                parentChildResultsProvider((
                  studentId: studentId,
                  session: session,
                  term: term,
                )),
              );
            },

            child: const Text(
              'Try Again',

              style: TextStyle(color: primary, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RESULT HELPERS
  // ============================================================

  String _subjectName(ParentResultModel result) {
    return result.subjectName;
  }

  String _score(ParentResultModel result) {
    return result.score.toString();
  }

  String _grade(ParentResultModel result) {
    return result.grade;
  }

  String _remark(ParentResultModel result) {
    return result.remark;
  }

  // ============================================================
  // GRADE COLOR
  // ============================================================

  Color _gradeColor(String grade) {
    switch (grade.toUpperCase().trim()) {
      case 'A+':
      case 'A':
        return Colors.green;

      case 'B+':
      case 'B':
        return Colors.blue;

      case 'C+':
      case 'C':
        return Colors.orange;

      case 'D':
        return Colors.deepOrange;

      case 'E':
      case 'F':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }
}
