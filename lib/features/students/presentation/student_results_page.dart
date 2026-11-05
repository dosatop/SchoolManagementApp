import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/presentation/widgets/student_ui.dart';
import 'package:app/features/students/provider/students_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Sort { score, name }

class StudentResultsPage extends ConsumerStatefulWidget {
  const StudentResultsPage({super.key});

  @override
  ConsumerState<StudentResultsPage> createState() => _StudentResultsPageState();
}

class _StudentResultsPageState extends ConsumerState<StudentResultsPage> {
  static const _params = StudentTermParams.current;

  // Score split used by the school.
  static const _testMax = 40;
  static const _examMax = 60;

  static const _testColor = Color(0xFF6366F1);
  static const _examColor = StudentColors.primary;

  _Sort _sort = _Sort.score;

  Future<void> _refresh() async {
    ref.invalidate(studentResultsProvider(_params));
    await sSafe(ref.read(studentResultsProvider(_params).future));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(studentResultsProvider(_params));
    final data = async.valueOrNull;
    final results = sList(data, ['results', 'subjects']);

    final session =
        sStr(data, ['session']) ??
        (results.isNotEmpty ? sStr(results.first, ['session']) : null);
    final term =
        sStr(data, ['term']) ??
        (results.isNotEmpty ? sStr(results.first, ['term']) : null);

    final subtitle = [
      if (term != null) '$term term',
      if (session != null) session,
    ].join(' · ');

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar(
        'Results',
        subtitle: subtitle.isEmpty ? 'This term' : subtitle,
      ),
      body: RefreshIndicator(
        color: StudentColors.primary,
        onRefresh: _refresh,
        child: () {
          if (async.isLoading && !async.hasValue) {
            return const StudentLoadingView(layout: LoadingLayout.summary);
          }

          if (async.hasError && !async.hasValue) {
            return StudentErrorView(
              error: async.error!,
              onRetry: _refresh,
              title: 'Unable to load results',
            );
          }

          if (results.isEmpty) {
            return const StudentEmptyView(
              icon: Icons.insights_rounded,
              title: 'No results yet',
              message:
                  'Your test and exam scores will show here once your '
                  'teachers upload them.',
            );
          }

          final scored = [
            for (final r in results)
              if (_total(r) != null) _total(r)!.toDouble(),
          ];

          final average = scored.isEmpty
              ? null
              : scored.reduce((a, b) => a + b) / scored.length;

          final best = _extreme(results, highest: true);
          final weakest = _extreme(results, highest: false);

          final grades = <String, int>{};
          for (final r in results) {
            final g = _grade(r);
            if (g != null) grades[g[0]] = (grades[g[0]] ?? 0) + 1;
          }

          final sorted = [...results]
            ..sort((a, b) {
              if (_sort == _Sort.name) {
                return _subject(a).toLowerCase().compareTo(
                  _subject(b).toLowerCase(),
                );
              }
              final ta = _total(a)?.toDouble() ?? -1;
              final tb = _total(b)?.toDouble() ?? -1;
              return tb.compareTo(ta);
            });

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
            children: [
              _summary(
                average: average,
                subjects: results.length,
                complete: scored.length,
              ),

              if (best != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _highlight(
                        icon: Icons.emoji_events_rounded,
                        label: 'Best subject',
                        subject: _subject(best),
                        score: _total(best)!,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    if (weakest != null &&
                        _subject(weakest) != _subject(best)) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _highlight(
                          icon: Icons.trending_up_rounded,
                          label: 'Needs focus',
                          subject: _subject(weakest),
                          score: _total(weakest)!,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              if (grades.isNotEmpty) ...[
                const SizedBox(height: 12),
                _gradeStrip(grades),
              ],

              const SizedBox(height: 24),

              Row(
                children: [
                  const Expanded(
                    child: SectionHeader(
                      'Subject results',
                      subtitle: 'Test /40 · Exam /60',
                    ),
                  ),
                  _sortToggle(),
                ],
              ),

              const SizedBox(height: 12),

              for (final r in sorted) ...[
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
  // SUMMARY
  // ================================================================

  Widget _summary({
    required double? average,
    required int subjects,
    required int complete,
  }) {
    final grade = average == null ? null : studentGradeFor(average);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: kStudentGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: StudentColors.primary.withValues(alpha: .24),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          ProgressRing(
            value: (average ?? 0) / 100,
            size: 92,
            stroke: 9,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  average == null ? '—' : '${average.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'average',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (grade != null)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          grade,
                          style: TextStyle(
                            color: studentGradeColor(grade),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    Flexible(
                      child: Text(
                        average == null
                            ? 'Scores not complete yet'
                            : _performance(average),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    HeroStat('Subjects', '$subjects'),
                    HeroStat('Scored', '$complete'),
                    HeroStat(
                      'Pending',
                      '${subjects - complete < 0 ? 0 : subjects - complete}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlight({
    required IconData icon,
    required String label,
    required String subject,
    required num score,
    required Color color,
  }) {
    return SoftCard(
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          IconBadge(icon, color: color, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10.5),
                ),
                Text(
                  subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudentColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${studentFmt(score)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradeStrip(Map<String, int> grades) {
    const order = ['A', 'B', 'C', 'D', 'E', 'F'];

    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          for (final g in order)
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (grades[g] ?? 0) > 0
                          ? studentGradeColor(g).withValues(alpha: .12)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      g,
                      style: TextStyle(
                        color: (grades[g] ?? 0) > 0
                            ? studentGradeColor(g)
                            : Colors.grey.shade400,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${grades[g] ?? 0}',
                    style: TextStyle(
                      color: (grades[g] ?? 0) > 0
                          ? StudentColors.textDark
                          : Colors.grey.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sortToggle() {
    return PopupMenuButton<_Sort>(
      initialValue: _sort,
      onSelected: (s) => setState(() => _sort = s),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => const [
        PopupMenuItem(value: _Sort.score, child: Text('Highest score')),
        PopupMenuItem(value: _Sort.name, child: Text('Subject A–Z')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE3E6EF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded, size: 16, color: Colors.grey.shade700),
            const SizedBox(width: 5),
            Text(
              _sort == _Sort.score ? 'Score' : 'A–Z',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // RESULT CARD
  // ================================================================

  Widget _resultCard(dynamic r) {
    final subject = _subject(r);
    final test = sNum(r, ['testScore', 'caScore', 'test']);
    final exam = sNum(r, ['examScore', 'exam']);
    final total = _total(r);
    final grade = _grade(r);
    final remark = sStr(r, ['remark', 'remarks', 'comment']);
    final position = sStr(r, ['position', 'subjectPosition']);
    final color = studentGradeColor(grade);

    return SoftCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  grade ?? '—',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      total == null
                          ? (test != null && exam == null
                                ? 'Waiting for exam score'
                                : 'Not complete yet')
                          : position == null
                          ? _performance(total.toDouble())
                          : '${_performance(total.toDouble())} · Position $position',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: total == null ? '—' : studentFmt(total),
                      style: const TextStyle(
                        color: StudentColors.textDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: '/100',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Stacked bar: test part + exam part of 100.
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 9,
              child: Row(
                children: [
                  _barPart(test, _testColor),
                  _barPart(exam, _examColor),
                  Expanded(
                    flex: (100 - (test ?? 0) - (exam ?? 0))
                        .clamp(0, 100)
                        .round(),
                    child: Container(color: Colors.grey.shade100),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _legend('Test', test, _testMax, _testColor),
              const SizedBox(width: 16),
              _legend('Exam', exam, _examMax, _examColor),
            ],
          ),

          if (remark != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: StudentColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 15,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      remark,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _barPart(num? value, Color color) {
    final flex = (value ?? 0).clamp(0, 100).round();
    if (flex == 0) return const SizedBox.shrink();
    return Expanded(flex: flex, child: Container(color: color));
  }

  Widget _legend(String label, num? value, int max, Color color) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        Text(
          value == null ? '—' : studentFmt(value),
          style: const TextStyle(
            color: StudentColors.textDark,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          '/$max',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
        ),
      ],
    );
  }

  // ================================================================
  // HELPERS
  // ================================================================

  String _subject(dynamic r) =>
      sStr(r, ['subjectName', 'subject', 'name']) ?? 'Subject';

  num? _total(dynamic r) {
    final total = sNum(r, ['totalScore', 'total', 'score']);
    if (total != null) return total;

    final test = sNum(r, ['testScore', 'caScore']);
    final exam = sNum(r, ['examScore']);
    if (test != null && exam != null) return test + exam;
    return null;
  }

  String? _grade(dynamic r) {
    final g = sStr(r, ['grade']);
    if (g != null) return g.toUpperCase();
    final t = _total(r);
    return t == null ? null : studentGradeFor(t.toDouble());
  }

  dynamic _extreme(List<dynamic> results, {required bool highest}) {
    dynamic pick;
    double? pickScore;
    for (final r in results) {
      final t = _total(r)?.toDouble();
      if (t == null) continue;
      if (pickScore == null || (highest ? t > pickScore : t < pickScore)) {
        pick = r;
        pickScore = t;
      }
    }
    return pick;
  }

  String _performance(double score) {
    if (score >= 70) return 'Excellent';
    if (score >= 60) return 'Very good';
    if (score >= 50) return 'Good';
    if (score >= 40) return 'Fair — keep pushing';
    return 'Needs improvement';
  }
}
