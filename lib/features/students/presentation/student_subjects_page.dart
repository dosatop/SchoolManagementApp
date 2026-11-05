import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/presentation/widgets/student_ui.dart';
import 'package:app/features/students/provider/students_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentSubjectsPage extends ConsumerStatefulWidget {
  const StudentSubjectsPage({super.key});

  @override
  ConsumerState<StudentSubjectsPage> createState() =>
      _StudentSubjectsPageState();
}

class _StudentSubjectsPageState extends ConsumerState<StudentSubjectsPage> {
  static const _term = StudentTermParams.current;

  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(studentSubjectsProvider);
    ref.invalidate(studentResultsProvider(_term));
    await Future.wait([
      sSafe(ref.read(studentSubjectsProvider.future)),
      sSafe(ref.read(studentResultsProvider(_term).future)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(studentSubjectsProvider);
    final subjects = sList(async.valueOrNull, ['subjects']);

    // Results are optional here — used to show this term's score.
    final results = sList(
      ref.watch(studentResultsProvider(_term)).valueOrNull,
      ['results', 'subjects'],
    );

    final q = _query.toLowerCase();
    final visible = q.isEmpty
        ? subjects
        : subjects.where((s) {
            final text = [
              sStr(s, ['subjectName', 'name', 'title']),
              sStr(s, ['code', 'subjectCode']),
              sStr(s, ['teacherName', 'teacher', 'teacherFullName']),
            ].whereType<String>().join(' ').toLowerCase();
            return text.contains(q);
          }).toList();

    final teachers = subjects
        .map((s) => sStr(s, ['teacherName', 'teacher', 'teacherFullName']))
        .whereType<String>()
        .toSet()
        .length;

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar(
        'My Subjects',
        subtitle: async.hasValue
            ? '${subjects.length} subject${subjects.length == 1 ? '' : 's'} this term'
            : null,
      ),
      body: RefreshIndicator(
        color: StudentColors.primary,
        onRefresh: _refresh,
        child: () {
          if (async.isLoading && !async.hasValue) {
            return const StudentLoadingView();
          }

          if (async.hasError && !async.hasValue) {
            return StudentErrorView(
              error: async.error!,
              onRetry: _refresh,
              title: 'Unable to load subjects',
            );
          }

          if (subjects.isEmpty) {
            return const StudentEmptyView(
              icon: Icons.menu_book_outlined,
              title: 'No subjects yet',
              message: 'Subjects added to your class will show up here.',
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
            children: [
              _summary(subjects.length, teachers),
              const SizedBox(height: 14),
              StudentSearchField(
                controller: _search,
                hint: 'Search subject, code or teacher',
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 44,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No subject matches "$_query"',
                        style: const TextStyle(
                          color: StudentColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (var i = 0; i < visible.length; i++) ...[
                  _subjectCard(
                    visible[i],
                    StudentColors.accents[
                        subjects.indexOf(visible[i]) %
                            StudentColors.accents.length],
                    _resultFor(visible[i], results),
                  ),
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

  Widget _summary(int subjects, int teachers) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: kStudentGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: StudentColors.primary.withValues(alpha: .22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
          const SizedBox(width: 16),
          HeroStat('Subjects', '$subjects'),
          HeroStat('Teachers', '$teachers'),
        ],
      ),
    );
  }

  // ================================================================
  // SUBJECT CARD
  // ================================================================

  Widget _subjectCard(dynamic item, Color color, dynamic result) {
    final name = sStr(item, ['subjectName', 'name', 'title']) ?? 'Subject';
    final code = sStr(item, ['code', 'subjectCode']);
    final teacher = sStr(item, ['teacherName', 'teacher', 'teacherFullName']);
    final department = sStr(item, ['departmentName', 'department']);
    final total = _total(result);

    return SoftCard(
      onTap: () => _openDetails(item, color, result),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: .75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: .25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              _abbrev(code ?? name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudentColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        teacher ?? 'Teacher not assigned',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: teacher == null
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (department != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      department,
                      style: TextStyle(
                        color: color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (total != null)
            ProgressRing(
              value: total / 100,
              size: 42,
              stroke: 4,
              color: studentGradeColor(studentGradeFor(total.toDouble())),
              trackColor: Colors.grey.shade100,
              child: Text(
                studentFmt(total),
                style: const TextStyle(
                  color: StudentColors.textDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  // ================================================================
  // DETAILS SHEET
  // ================================================================

  void _openDetails(dynamic item, Color color, dynamic result) {
    final name = sStr(item, ['subjectName', 'name', 'title']) ?? 'Subject';
    final code = sStr(item, ['code', 'subjectCode']);
    final teacher = sStr(item, ['teacherName', 'teacher', 'teacherFullName']);
    final teacherEmail = sStr(item, ['teacherEmail', 'email']);
    final department = sStr(item, ['departmentName', 'department']);
    final trade = sStr(item, ['tradeName', 'trade']);

    final test = sNum(result, ['testScore', 'caScore', 'test']);
    final exam = sNum(result, ['examScore', 'exam']);
    final total = _total(result);
    final grade =
        sStr(result, ['grade']) ??
        (total == null ? null : studentGradeFor(total.toDouble()));
    final remark = sStr(result, ['remark', 'remarks', 'comment']);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * .8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetHandle(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        _abbrev(code ?? name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: StudentColors.textDark,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (code != null)
                            Text(
                              code,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _detailRow(
                  Icons.person_outline_rounded,
                  'Teacher',
                  teacher ?? 'Not assigned yet',
                  color,
                ),
                if (teacherEmail != null && teacherEmail.contains('@'))
                  _detailRow(
                    Icons.email_outlined,
                    'Teacher email',
                    teacherEmail,
                    color,
                  ),
                if (department != null)
                  _detailRow(
                    Icons.account_tree_outlined,
                    'Department',
                    department,
                    color,
                  ),
                if (trade != null)
                  _detailRow(Icons.handyman_outlined, 'Trade', trade, color),
                const SizedBox(height: 16),
                const Text(
                  'This term',
                  style: TextStyle(
                    color: StudentColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                if (total == null && test == null && exam == null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: StudentColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'No scores uploaded for this subject yet.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.5,
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      _scoreBox('Test', test, 40),
                      const SizedBox(width: 8),
                      _scoreBox('Exam', exam, 60),
                      const SizedBox(width: 8),
                      _scoreBox('Total', total, 100, grade: grade),
                    ],
                  ),
                if (remark != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.format_quote_rounded, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            remark,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 12.5,
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
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          IconBadge(icon, color: color, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: StudentColors.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreBox(String label, num? value, int max, {String? grade}) {
    final color = grade != null
        ? studentGradeColor(grade)
        : StudentColors.primary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value == null ? '—' : studentFmt(value),
              style: TextStyle(
                color: color,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              grade == null ? '$label / $max' : '$label · $grade',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // HELPERS
  // ================================================================

  dynamic _resultFor(dynamic subject, List<dynamic> results) {
    final id = sStr(subject, ['subjectId', 'id']);
    final name = sStr(subject, ['subjectName', 'name'])?.toLowerCase();

    for (final r in results) {
      if (id != null && sStr(r, ['subjectId']) == id) return r;
    }
    for (final r in results) {
      if (name != null &&
          sStr(r, ['subjectName', 'subject', 'name'])?.toLowerCase() == name) {
        return r;
      }
    }
    return null;
  }

  num? _total(dynamic r) {
    if (r == null) return null;
    final total = sNum(r, ['totalScore', 'total', 'score']);
    if (total != null) return total;

    final test = sNum(r, ['testScore', 'caScore']);
    final exam = sNum(r, ['examScore']);
    if (test != null && exam != null) return test + exam;
    return null;
  }

  /// "MTH" from a code, or the first letters of the name.
  String _abbrev(String text) {
    final clean = text.trim();
    if (clean.length <= 4 && !clean.contains(' ')) return clean.toUpperCase();

    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.length == 1) {
      final w = words.first;
      return w.substring(0, w.length < 3 ? w.length : 3).toUpperCase();
    }
    return words.take(3).map((w) => w[0]).join().toUpperCase();
  }
}
