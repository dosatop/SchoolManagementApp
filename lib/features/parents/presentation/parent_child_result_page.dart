import 'package:app/features/parents/parent_provider.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==================================================================
// PARENT: CHILD RESULTS
// ==================================================================
// Leave session/term null for the school's current session and term.

class ParentChildResultsPage extends ConsumerWidget {
  const ParentChildResultsPage({
    super.key,
    required this.studentId,
    this.session,
    this.term,
    this.header,
  });

  final String studentId;

  /// Optional widget above the content (the dashboard passes a child
  /// switcher when this page is shown as a tab).
  final Widget? header;
  final String? session;
  final String? term;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ParentChildTermParams(
      studentId,
      session: session,
      term: term,
    );

    final async = ref.watch(parentChildResultsDataProvider(params));
    final data = async.valueOrNull;

    final results = sList(data, ['results']);
    final usedSession = sStr(data, ['session']) ?? session;
    final usedTerm = sStr(data, ['term']) ?? term;
    final childName = sStr(data is Map ? data['student'] : null, ['fullName']);

    Future<void> refresh() async {
      ref.invalidate(parentChildResultsDataProvider(params));
      await sSafe(ref.read(parentChildResultsDataProvider(params).future));
    }

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar(
        'Results',
        subtitle: [
          if (childName != null) childName,
          if (usedTerm != null) usedTerm,
          if (usedSession != null) usedSession,
        ].join(' · '),
      ),
      body: _withHeader(header, RefreshIndicator(
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
            return StudentEmptyView(
              icon: Icons.bar_chart_rounded,
              title: 'No results yet',
              message: usedTerm == null
                  ? 'Results will show here once the teachers upload them.'
                  : 'No results have been uploaded for $usedTerm yet.',
            );
          }

          final scores = [
            for (final r in results)
              if (sNum(r, ['score', 'totalScore']) != null)
                sNum(r, ['score', 'totalScore'])!.toDouble(),
          ];

          final average =
              sNum(data, ['averageScore'])?.toDouble() ??
              (scores.isEmpty
                  ? null
                  : scores.reduce((a, b) => a + b) / scores.length);

          final best = scores.isEmpty
              ? null
              : scores.reduce((a, b) => a > b ? a : b);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            children: [
              StudentSummaryCard(
                label: 'Average score',
                value: average == null ? '—' : '${average.toStringAsFixed(1)}%',
                caption: average == null ? 'Scores not complete' : _performance(average),
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
      )),
    );
  }

  Widget _resultCard(dynamic r) {
    final subject = sStr(r, ['subjectName', 'subject']) ?? 'Subject';
    final test = sNum(r, ['testScore']);
    final exam = sNum(r, ['examScore']);
    final total = sNum(r, ['score', 'totalScore']) ??
        (test != null && exam != null ? test + exam : null);
    final grade = sStr(r, ['grade']) ??
        (total == null ? null : _gradeFor(total.toDouble()));
    final remark = sStr(r, ['remark', 'remarks']);
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

  /// Adjust to your school's grading scale.
  String _gradeFor(double score) {
    if (score >= 70) return 'A';
    if (score >= 60) return 'B';
    if (score >= 50) return 'C';
    if (score >= 45) return 'D';
    if (score >= 40) return 'E';
    return 'F';
  }

  Color _gradeColor(String? grade) {
    final g = (grade == null || grade.isEmpty) ? '' : grade[0].toUpperCase();
    switch (g) {
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
    if (average >= 40) return 'Fair — needs a push';
    return 'Needs improvement';
  }

  String _fmt(num n) =>
      n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);
}

/// Puts an optional [header] (e.g. a child switcher) above [body].
Widget _withHeader(Widget? header, Widget body) {
  if (header == null) return body;
  return Column(children: [header, Expanded(child: body)]);
}