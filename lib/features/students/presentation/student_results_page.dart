import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/provider/students_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentResultsPage extends ConsumerWidget {
  const StudentResultsPage({super.key});

  static const _params = StudentTermParams.current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentResultsProvider(_params));
    final data = async.valueOrNull;
    final results = sList(data, ['results', 'subjects']);

    final session = sStr(data, ['session']) ??
        (results.isNotEmpty ? sStr(results.first, ['session']) : null);
    final term = sStr(data, ['term']) ??
        (results.isNotEmpty ? sStr(results.first, ['term']) : null);

    Future<void> refresh() async {
      ref.invalidate(studentResultsProvider(_params));
      await sSafe(ref.read(studentResultsProvider(_params).future));
    }

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar(
        'Results',
        subtitle: [
          if (term != null) term,
          if (session != null) session,
        ].join(' · ').ifEmpty('This term'),
      ),
      body: RefreshIndicator(
        color: StudentColors.primary,
        onRefresh: refresh,
        child: () {
          if (async.isLoading && !async.hasValue) {
            return const StudentLoadingView(layout: LoadingLayout.summary);
          }

          if (async.hasError && !async.hasValue) {
            return StudentErrorView(
              error: async.error!,
              onRetry: refresh,
              title: 'Unable to load results',
            );
          }

          if (results.isEmpty) {
            return const StudentEmptyView(
              icon: Icons.bar_chart_rounded,
              title: 'No results yet',
              message:
                  'Your test and exam scores will show here once your teachers upload them.',
            );
          }

          final totals = [
            for (final r in results)
              if (_total(r) != null) _total(r)!.toDouble(),
          ];

          final average = totals.isEmpty
              ? null
              : totals.reduce((a, b) => a + b) / totals.length;

          final best = totals.isEmpty
              ? null
              : totals.reduce((a, b) => a > b ? a : b);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            children: [
              StudentSummaryCard(
                label: 'Average score',
                value: average == null ? '—' : '${average.toStringAsFixed(1)}%',
                caption: average == null
                    ? 'Scores are not complete yet'
                    : _performance(average),
                progress: average == null ? null : average / 100,
                icon: Icons.emoji_events_outlined,
                footer: Row(
                  children: [
                    SummaryStat('Subjects', '${results.length}'),
                    SummaryStat(
                      'Best',
                      best == null ? '—' : '${best.toStringAsFixed(0)}%',
                    ),
                    SummaryStat(
                      'Grade',
                      average == null ? '—' : _gradeFor(average),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Subject results',
                style: TextStyle(
                  color: StudentColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              for (final r in results) ...[
                _resultCard(r),
                const SizedBox(height: 10),
              ],
            ],
          );
        }(),
      ),
    );
  }

  // ================================================================
  // RESULT CARD
  // ================================================================

  Widget _resultCard(dynamic r) {
    final subject = sStr(r, ['subjectName', 'subject', 'name']) ?? 'Subject';
    final test = sNum(r, ['testScore', 'caScore', 'test']);
    final exam = sNum(r, ['examScore', 'exam']);
    final total = _total(r);
    final grade = sStr(r, ['grade']) ??
        (total == null ? null : _gradeFor(total.toDouble()));
    final remark = sStr(r, ['remark', 'remarks', 'comment']);
    final color = _gradeColor(grade);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: StudentColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total == null ? 'Not complete' : '${_fmt(total)} / 100',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  grade ?? '—',
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          if (total != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (total / 100).clamp(0, 1).toDouble(),
                minHeight: 7,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],

          if (test != null || exam != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _scorePill('Test', test),
                const SizedBox(width: 8),
                _scorePill('Exam', exam),
              ],
            ),
          ],

          if (remark != null) ...[
            const SizedBox(height: 10),
            Text(
              remark,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _scorePill(String label, num? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: StudentColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label  ${value == null ? '—' : _fmt(value)}',
        style: const TextStyle(
          color: StudentColors.textDark,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ================================================================
  // HELPERS
  // ================================================================

  num? _total(dynamic r) {
    final total = sNum(r, ['totalScore', 'total', 'score']);
    if (total != null) return total;

    final test = sNum(r, ['testScore', 'caScore']);
    final exam = sNum(r, ['examScore']);
    if (test != null && exam != null) return test + exam;

    return null;
  }

  /// Common Nigerian school grading. Adjust to your school's scale.
  String _gradeFor(double score) {
    if (score >= 70) return 'A';
    if (score >= 60) return 'B';
    if (score >= 50) return 'C';
    if (score >= 45) return 'D';
    if (score >= 40) return 'E';
    return 'F';
  }

  Color _gradeColor(String? grade) {
    switch (grade?.toUpperCase().substring(0, 1)) {
      case 'A':
        return Colors.green.shade600;
      case 'B':
        return Colors.blue.shade600;
      case 'C':
        return Colors.teal.shade600;
      case 'D':
      case 'E':
        return Colors.orange.shade700;
      case 'F':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _performance(double average) {
    if (average >= 70) return 'Excellent performance';
    if (average >= 60) return 'Very good performance';
    if (average >= 50) return 'Good performance';
    if (average >= 40) return 'Fair — keep pushing';
    return 'Needs improvement';
  }

  String _fmt(num n) =>
      n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}