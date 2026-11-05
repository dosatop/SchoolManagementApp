import 'package:app/features/admin/models/results/admin_result_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/presentation/widgets/student_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ==================================================================
// ADMIN: ONE STUDENT'S RESULTS
// ==================================================================
// Results are grouped by period (session + term). The page opens on
// the period it was launched with, or the newest one.
// ==================================================================

class AdminResultDetailsPage extends ConsumerStatefulWidget {
  final String schoolId;
  final String studentId;

  final String studentName;
  final String studentNumber;
  final String className;
  final String session;
  final String term;

  final List<AdminResultModel> results;

  const AdminResultDetailsPage({
    super.key,
    required this.schoolId,
    required this.studentId,
    required this.studentName,
    required this.studentNumber,
    required this.className,
    required this.session,
    required this.term,
    required this.results,
  });

  @override
  ConsumerState<AdminResultDetailsPage> createState() =>
      _AdminResultDetailsPageState();
}

class _AdminResultDetailsPageState
    extends ConsumerState<AdminResultDetailsPage> {
  static const Color primary = StudentColors.primary;
  static const Color textDark = StudentColors.textDark;

  late List<AdminResultModel> _results;

  /// "session|term", or null for every period.
  String? _period;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _results = List<AdminResultModel>.from(widget.results);

    final periods = _periods();
    final launched = '${widget.session.trim()}|${widget.term.trim()}';
    _period = periods.contains(launched)
        ? launched
        : periods.isNotEmpty
        ? periods.first
        : null;
  }

  // ================================================================
  // HELPERS
  // ================================================================

  static double _n(Object? v) {
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}') ?? 0;
  }

  static bool _examDone(AdminResultModel r) => _n(r.examScore) > 0;

  static String _key(AdminResultModel r) =>
      '${r.session.trim()}|${r.term.trim()}';

  static int _termOrder(String t) {
    final s = t.toLowerCase();
    if (s.startsWith('1') || s.startsWith('first')) return 1;
    if (s.startsWith('2') || s.startsWith('second')) return 2;
    if (s.startsWith('3') || s.startsWith('third')) return 3;
    return 9;
  }

  static String _termLabel(String term) {
    final t = term.trim();
    if (t.isEmpty) return '';
    return t.toLowerCase().contains('term') ? t : '$t term';
  }

  static String _periodLabel(String key) {
    final parts = key.split('|');
    final session = parts.first.trim();
    final term = parts.length > 1 ? _termLabel(parts[1]) : '';
    return [session, term].where((s) => s.isNotEmpty).join(' · ');
  }

  /// Newest period first.
  List<String> _periods() {
    final keys = _results.map(_key).toSet().toList();
    keys.sort((a, b) {
      final pa = a.split('|'), pb = b.split('|');
      final s = pb.first.compareTo(pa.first);
      if (s != 0) return s;
      return _termOrder(pb.last).compareTo(_termOrder(pa.last));
    });
    return keys;
  }

  List<AdminResultModel> get _visible {
    final list = _period == null
        ? [..._results]
        : _results.where((r) => _key(r) == _period).toList();
    list.sort((a, b) => _n(b.score).compareTo(_n(a.score)));
    return list;
  }

  String get _name {
    final n = widget.studentName.trim();
    return n.isEmpty ? 'Student' : n;
  }

  void _snack(String text, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          content: Text(text),
        ),
      );
  }

  // ================================================================
  // EDIT / DELETE
  // ================================================================

  Future<void> _edit(AdminResultModel result) async {
    final updated = await context.push<AdminResultModel>(
      '/admin/${widget.schoolId}/edit-result/${result.resultId}',
      extra: result,
    );

    if (!mounted || updated == null) return;

    setState(() {
      final i = _results.indexWhere((r) => r.resultId == updated.resultId);
      if (i != -1) _results[i] = updated;
    });
  }

  Future<void> _delete(AdminResultModel result) async {
    final subject = result.subjectName.trim().isEmpty
        ? 'this subject'
        : result.subjectName.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: Icon(
          Icons.delete_outline_rounded,
          color: Colors.red.shade600,
          size: 30,
        ),
        title: const Text(
          'Delete result?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'The $subject result for $_name will be removed. '
          'This cannot be undone.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);

    var ok = false;
    try {
      ok = await ref
          .read(adminDashboardProvider.notifier)
          .deleteResult(resultId: result.resultId);
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;
    setState(() => _busy = false);

    if (ok) {
      setState(() {
        _results.removeWhere((r) => r.resultId == result.resultId);
        if (_period != null && !_periods().contains(_period)) {
          final p = _periods();
          _period = p.isEmpty ? null : p.first;
        }
      });
      _snack('$subject result deleted', color: Colors.green.shade700);
    } else {
      _snack('Unable to delete the result.', color: Colors.red.shade700);
    }
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final periods = _periods();
    final visible = _visible;

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar('Student results', subtitle: _name),
      body: Stack(
        children: [
          ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
            children: [
              _hero(visible),
              if (periods.length > 1) ...[
                const SizedBox(height: 14),
                PillTabs<String?>(
                  padding: EdgeInsets.zero,
                  selected: _period,
                  onChanged: (v) => setState(() => _period = v),
                  tabs: [
                    for (final p in periods)
                      PillTab<String?>(
                        p,
                        _periodLabel(p),
                        count: _results.where((r) => _key(r) == p).length,
                      ),
                    PillTab<String?>(
                      null,
                      'All periods',
                      count: _results.length,
                      color: Colors.teal,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Subjects',
                      style: TextStyle(
                        color: textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    'highest first',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (visible.isEmpty)
                _empty()
              else
                for (final r in visible) ...[
                  _resultCard(r, showPeriod: _period == null),
                  const SizedBox(height: 10),
                ],
            ],
          ),
          if (_busy)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.white.withValues(alpha: .55),
                child: const Center(
                  child: CircularProgressIndicator(color: primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ================================================================
  // HERO
  // ================================================================

  Widget _hero(List<AdminResultModel> results) {
    final done = results.where(_examDone).toList();
    final average = done.isEmpty
        ? null
        : done.fold<double>(0, (s, r) => s + _n(r.score)) / done.length;
    final passed = done.where((r) => _n(r.score) >= 40).length;
    final failed = done.length - passed;
    final pending = results.length - done.length;

    final number = widget.studentNumber.trim();
    final className = widget.className.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: kStudentGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: .25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .16),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            studentInitials(_name, fallback: 'S'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (number.isNotEmpty)
                          _heroChip(Icons.badge_outlined, 'No. $number'),
                        if (className.isNotEmpty)
                          _heroChip(Icons.class_outlined, className),
                        if (_period != null)
                          _heroChip(
                            Icons.calendar_month_rounded,
                            _periodLabel(_period!),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ProgressRing(
                value: (average ?? 0) / 100,
                size: 84,
                stroke: 8,
                trackColor: Colors.white.withValues(alpha: .18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      average == null ? '—' : studentFmt(average),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      average == null ? 'average' : studentGradeFor(average),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: .15)),
          const SizedBox(height: 12),
          Row(
            children: [
              HeroStat('Subjects', '${results.length}'),
              HeroStat('Passed', '$passed'),
              HeroStat('Failed', '$failed'),
              HeroStat('Pending', '$pending'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // RESULT CARD
  // ================================================================

  Widget _resultCard(AdminResultModel r, {required bool showPeriod}) {
    final subject = r.subjectName.trim().isEmpty
        ? 'Subject'
        : r.subjectName.trim();
    final code = r.subjectCode.trim();
    final test = _n(r.testScore);
    final exam = _n(r.examScore);
    final total = _n(r.score);
    final done = _examDone(r);
    final grade = r.grade.trim().isNotEmpty
        ? r.grade.trim()
        : (done ? studentGradeFor(total) : '');
    final color = done ? studentGradeColor(grade) : Colors.blueGrey;
    final remark = r.remark.trim();

    return SoftCard(
      onTap: () => _showDetails(r),
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  done ? (grade.isEmpty ? '—' : grade) : '…',
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
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
                        color: textDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (code.isNotEmpty) code,
                        if (showPeriod) _periodLabel(_key(r)),
                      ].join(' · '),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                done ? studentFmt(total) : studentFmt(test),
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                done ? '/100' : '/40',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
              PopupMenuButton<String>(
                tooltip: 'Actions',
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (v) {
                  if (v == 'edit') _edit(r);
                  if (v == 'delete') _delete(r);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 19),
                        SizedBox(width: 10),
                        Text('Edit scores'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 19,
                          color: Colors.red.shade600,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Delete',
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _scoreBar(test, exam),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _legend(Colors.blue.shade400, 'Test ${studentFmt(test)}/40'),
              done
                  ? _legend(
                      Colors.purple.shade400,
                      'Exam ${studentFmt(exam)}/60',
                    )
                  : _legend(Colors.orange, 'Exam not entered'),
            ],
          ),
          if (remark.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 15,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    remark,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _scoreBar(double test, double exam) {
    final t = test.clamp(0, 40).toDouble();
    final e = exam.clamp(0, 60).toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 8,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth - 2;
            return Row(
              children: [
                SizedBox(
                  width: w * .4,
                  child: Stack(
                    children: [
                      Container(color: Colors.blue.shade50),
                      FractionallySizedBox(
                        widthFactor: t / 40,
                        child: Container(color: Colors.blue.shade400),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 2),
                SizedBox(
                  width: w * .6,
                  child: Stack(
                    children: [
                      Container(color: Colors.purple.shade50),
                      FractionallySizedBox(
                        widthFactor: e / 60,
                        child: Container(color: Colors.purple.shade400),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _legend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // DETAILS SHEET
  // ================================================================

  void _showDetails(AdminResultModel r) {
    final subject = r.subjectName.trim().isEmpty
        ? 'Subject'
        : r.subjectName.trim();
    final test = _n(r.testScore);
    final exam = _n(r.examScore);
    final total = _n(r.score);
    final done = _examDone(r);
    final grade = r.grade.trim().isNotEmpty
        ? r.grade.trim()
        : (done ? studentGradeFor(total) : '');
    final color = done ? studentGradeColor(grade) : Colors.blueGrey;
    final remark = r.remark.trim();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetHandle(),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: const TextStyle(
                              color: textDark,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [
                              if (r.subjectCode.trim().isNotEmpty)
                                r.subjectCode.trim(),
                              _periodLabel(_key(r)),
                            ].where((s) => s.isNotEmpty).join(' · '),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ProgressRing(
                      value: (done ? total : test) / (done ? 100 : 40),
                      size: 70,
                      stroke: 7,
                      color: color,
                      trackColor: Colors.grey.shade200,
                      child: Text(
                        done ? (grade.isEmpty ? '—' : grade) : '…',
                        style: TextStyle(
                          color: color,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _scoreTile('Test', test, 40, Colors.blue.shade500),
                    const SizedBox(width: 8),
                    done
                        ? _scoreTile('Exam', exam, 60, Colors.purple.shade500)
                        : _pendingTile(),
                    const SizedBox(width: 8),
                    _scoreTile(
                      'Total',
                      done ? total : test,
                      100,
                      color,
                      highlight: true,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: StudentColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          remark.isEmpty ? 'No remark added.' : remark,
                          style: TextStyle(
                            color: remark.isEmpty
                                ? Colors.grey.shade500
                                : textDark,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _delete(r);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade200),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 19),
                        label: const Text('Delete'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _edit(r);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: primary,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 19),
                        label: const Text('Edit scores'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scoreTile(
    String label,
    double value,
    int max,
    Color color, {
    bool highlight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: highlight ? .12 : .07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: studentFmt(value),
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: '/$max',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pendingTile() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              'Exam',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pending',
              style: TextStyle(
                color: Colors.orange.shade800,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
      child: Column(
        children: [
          const IconBadge(
            Icons.assessment_outlined,
            color: primary,
            size: 64,
            circle: true,
          ),
          const SizedBox(height: 14),
          const Text(
            'No results here',
            style: TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'This student has no results for the selected period.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}