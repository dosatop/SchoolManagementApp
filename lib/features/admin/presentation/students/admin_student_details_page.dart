import 'package:app/features/admin/models/students/admin_student_detail_model.dart';
import 'package:app/features/admin/models/students/admin_student_model.dart';
import 'package:app/features/admin/models/students/admin_student_parent_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:app/features/admin/providers/admin_student_provider.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/presentation/widgets/student_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ==================================================================
// ADMIN: STUDENT DETAILS
// ==================================================================
// Two sources of data:
//   • adminStudentDetailsProvider  → full profile (results, tasks…)
//   • adminDashboardProvider       → the basic row from the list
//
// If the details request fails, the page still shows the basic row
// with a banner explaining what failed, instead of a dead end.
// ==================================================================

enum _Tab { overview, results, tasks, parents }

class AdminStudentDetailsPage extends ConsumerStatefulWidget {
  final String schoolId;
  final String studentId;

  const AdminStudentDetailsPage({
    super.key,
    required this.schoolId,
    required this.studentId,
  });

  @override
  ConsumerState<AdminStudentDetailsPage> createState() =>
      _AdminStudentDetailsPageState();
}

class _AdminStudentDetailsPageState
    extends ConsumerState<AdminStudentDetailsPage> {
  static const Color primary = StudentColors.primary;
  static const Color textDark = StudentColors.textDark;

  _Tab _tab = _Tab.overview;
  bool _busy = false;

  String get _id => widget.studentId;

  // ================================================================
  // HELPERS
  // ================================================================

  static String? _clean(String? s) =>
      s == null || s.trim().isEmpty ? null : s.trim();

  AdminStudentModel? _basicRow() {
    final students = ref.read(adminDashboardProvider).valueOrNull?.students;
    return students?.where((s) => s.studentId == _id).firstOrNull;
  }

  Future<void> _refresh() async {
    ref.invalidate(adminStudentDetailsProvider(_id));
    try {
      await ref.read(adminStudentDetailsProvider(_id).future);
    } catch (_) {
      // Shown by the banner.
    }
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

  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    _snack('$label copied');
  }

  /// Short, human message for an error + whether it's a data/parsing bug.
  static ({String message, bool parseBug}) _describe(Object error) {
    if (error is TypeError || error is FormatException) {
      return (
        message:
            "The server replied, but the app couldn't read this student's "
            'data. Some details are hidden until this is fixed.',
        parseBug: true,
      );
    }
    final text = error
        .toString()
        .replaceFirst(RegExp(r'^[A-Za-z]*Exception(\s*\[[^\]]*\])?:\s*'), '')
        .trim();
    return (
      message: text.isEmpty || text.startsWith('Instance of')
          ? 'Something went wrong while loading this student.'
          : text,
      parseBug: false,
    );
  }

  // ================================================================
  // EDIT
  // ================================================================

  void _edit() {
    final row = _basicRow();
    if (row == null) {
      _snack(
        'Student information is still loading. Try again in a moment.',
        color: Colors.red.shade700,
      );
      return;
    }

    context
        .push('/admin/${widget.schoolId}/edit-student/$_id', extra: row)
        .then((_) {
          if (!mounted) return;
          ref.invalidate(adminStudentDetailsProvider(_id));
        });
  }

  // ================================================================
  // DELETE
  // ================================================================

  Future<void> _delete(String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: Colors.red.shade600,
            size: 28,
          ),
        ),
        title: const Text(
          'Delete student?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          '$name will be removed from the school, along with their results, '
          'attendance and parent links.\n\nThis cannot be undone.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade700, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    setState(() => _busy = true);

    var success = false;
    String? failure;

    try {
      final result = await ref
          .read(adminDashboardProvider.notifier)
          .deleteStudent(studentId: _id);
      success = result == true;
    } catch (e) {
      failure = _describe(e).message;
    }

    if (!mounted) return;
    setState(() => _busy = false);

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade700,
          content: Text('$name was deleted'),
        ),
      );
      router.pop();
    } else {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          content: Text(failure ?? 'Unable to delete student.'),
        ),
      );
    }
  }

  // ================================================================
  // TRADE
  // ================================================================

  Future<void> _openTradeSheet(AdminStudentDetailModel student) async {
    final dashboard = ref.read(adminDashboardProvider).valueOrNull;

    if (dashboard == null) {
      _snack('School data is still loading.', color: Colors.red.shade700);
      return;
    }

    final trades = dashboard.trades
        .where((t) => t.schoolId == widget.schoolId)
        .toList();

    if (trades.isEmpty) {
      _snack(
        'No trades exist yet. Create one under Departments & trades.',
        color: Colors.orange.shade800,
      );
      return;
    }

    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TradeSheet(
        student: student,
        trades: [for (final t in trades) (id: t.tradeId, name: t.tradeName)],
        subjects: [
          for (final s in dashboard.subjects)
            if (_clean(s.tradeId) != null)
              (id: s.subjectId, name: s.subjectName, tradeId: s.tradeId!),
        ],
      ),
    );

    if (message == null || !mounted) return;

    ref.invalidate(adminStudentDetailsProvider(_id));
    ref.read(adminDashboardProvider.notifier).refresh();
    _snack(message, color: Colors.green.shade700);
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminStudentDetailsProvider(_id));
    final students = ref.watch(adminDashboardProvider).valueOrNull?.students;
    final basic = students?.where((s) => s.studentId == _id).firstOrNull;
    final detail = async.valueOrNull;

    final name =
        _clean(detail?.studentName) ?? _clean(basic?.studentName) ?? 'Student';

    final loadingDetail = async.isLoading && detail == null;
    final failed = async.hasError && detail == null;

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar(
        'Student profile',
        subtitle: detail == null && basic == null ? null : name,
        actions: [
          IconButton(
            tooltip: 'Edit student',
            onPressed: _busy ? null : _edit,
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            enabled: !_busy,
            tooltip: 'More',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (v) {
              if (v == 'refresh') _refresh();
              if (v == 'delete') _delete(name);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 20),
                    SizedBox(width: 10),
                    Text('Refresh'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Colors.red.shade600,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Delete student',
                      style: TextStyle(color: Colors.red.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          if (loadingDetail && basic == null)
            _loadingView()
          else if (failed && basic == null)
            _fullError(async.error!)
          else
            RefreshIndicator(
              color: primary,
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                children: [
                  _hero(detail, basic, name, loading: loadingDetail),
                  const SizedBox(height: 14),
                  if (failed) ...[
                    _errorBanner(async.error!),
                    const SizedBox(height: 14),
                    _basicOverview(basic!),
                  ] else if (detail == null)
                    _sectionShimmer()
                  else ...[
                    PillTabs<_Tab>(
                      padding: EdgeInsets.zero,
                      selected: _tab,
                      onChanged: (t) => setState(() => _tab = t),
                      tabs: [
                        const PillTab(_Tab.overview, 'Overview'),
                        PillTab(
                          _Tab.results,
                          'Results',
                          count: detail.results.length,
                        ),
                        PillTab(
                          _Tab.tasks,
                          'Tasks',
                          count: detail.assignments.length,
                        ),
                        PillTab(
                          _Tab.parents,
                          'Parents',
                          count: detail.parents.length,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: KeyedSubtree(
                        key: ValueKey(_tab),
                        child: switch (_tab) {
                          _Tab.overview => _overview(detail),
                          _Tab.results => _results(detail),
                          _Tab.tasks => _tasks(detail),
                          _Tab.parents => _parents(detail),
                        },
                      ),
                    ),
                  ],
                ],
              ),
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

  Widget _hero(
    AdminStudentDetailModel? d,
    AdminStudentModel? b,
    String name, {
    required bool loading,
  }) {
    final number = _clean(d?.studentNumber) ?? _clean(b?.studentNumber);
    final className = _clean(d?.className) ?? _clean(b?.className);
    final department = _clean(d?.departmentName) ?? _clean(b?.departmentName);
    final trade = _clean(d?.tradeName) ?? _clean(b?.tradeName);
    final level = _classType(className ?? '');

    final finished = (d?.results ?? const [])
        .where((r) => r.examScore > 0)
        .toList();
    final average = finished.isEmpty
        ? null
        : finished.fold<double>(0, (s, r) => s + r.score) / finished.length;

    final parentCount = d?.parents.length ?? b?.parentCount ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .35),
                    width: 2,
                  ),
                ),
                child: Text(
                  studentInitials(name, fallback: 'S'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    if (number != null) ...[
                      const SizedBox(height: 5),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _copy(number, 'Student number'),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'No. $number',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .8),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Icon(
                              Icons.copy_rounded,
                              size: 13,
                              color: Colors.white.withValues(alpha: .7),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _heroChip(Icons.class_outlined, className ?? 'No class'),
              if (level != 'Unknown')
                _heroChip(
                  level == 'Senior'
                      ? Icons.trending_up_rounded
                      : Icons.school_outlined,
                  level,
                ),
              if (department != null)
                _heroChip(Icons.account_tree_outlined, department),
              if (trade != null) _heroChip(Icons.construction_outlined, trade),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withValues(alpha: .15)),
          const SizedBox(height: 14),
          Row(
            children: [
              HeroStat(
                'Average',
                average == null ? '—' : '${studentFmt(average)}%',
                loading: loading,
              ),
              HeroStat(
                'Subjects',
                '${d?.subjects.length ?? '—'}',
                loading: loading,
              ),
              HeroStat(
                'Tasks',
                '${d?.assignments.length ?? '—'}',
                loading: loading,
              ),
              HeroStat('Parents', '$parentCount'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // OVERVIEW
  // ================================================================

  Widget _overview(AdminStudentDetailModel s) {
    final email = _clean(s.email);
    final phone = _clean(s.phoneNumber);
    final school = _clean(s.schoolName);

    return Column(
      children: [
        _card(
          title: 'Contact',
          icon: Icons.contact_mail_outlined,
          child: Column(
            children: [
              _infoRow(
                Icons.alternate_email_rounded,
                'Email',
                email ?? 'Not added',
                onCopy: email == null ? null : () => _copy(email, 'Email'),
              ),
              _divider(),
              _infoRow(
                Icons.phone_outlined,
                'Phone',
                phone ?? 'Not added',
                onCopy: phone == null ? null : () => _copy(phone, 'Phone'),
              ),
              _divider(),
              _infoRow(Icons.school_outlined, 'School', school ?? '—'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _placement(s),
        const SizedBox(height: 12),
        _subjects(s),
      ],
    );
  }

  Widget _placement(AdminStudentDetailModel s) {
    final className = _clean(s.className);
    final level = _classType(className ?? '');
    final department = _clean(s.departmentName);
    final trade = _clean(s.tradeName);
    final tradeSubject = _clean(s.tradeSubjectName);

    return _card(
      title: 'Academic placement',
      icon: Icons.account_tree_outlined,
      trailing: TextButton.icon(
        onPressed: () => _openTradeSheet(s),
        style: TextButton.styleFrom(
          foregroundColor: trade == null ? primary : Colors.deepOrange,
          backgroundColor: (trade == null ? primary : Colors.deepOrange)
              .withValues(alpha: .08),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(0, 34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: Icon(
          trade == null ? Icons.add_rounded : Icons.swap_horiz_rounded,
          size: 16,
        ),
        label: Text(
          trade == null ? 'Assign trade' : 'Change',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _tile(
                  Icons.class_outlined,
                  'Class',
                  className,
                  primary,
                  empty: 'No class',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _tile(
                  Icons.layers_outlined,
                  'Level',
                  level == 'Unknown' ? null : level,
                  level == 'Senior' ? Colors.indigo : Colors.teal,
                  empty: 'Unknown',
                ),
              ),
            ],
          ),
          if (level == 'Senior' || department != null) ...[
            const SizedBox(height: 10),
            _tile(
              Icons.account_tree_outlined,
              'Department',
              department,
              Colors.blue,
              empty: 'No department yet',
            ),
          ],
          const SizedBox(height: 10),
          _tile(
            Icons.construction_outlined,
            'Trade',
            trade,
            Colors.deepOrange,
            empty: 'No trade yet',
          ),
          if (trade != null) ...[
            const SizedBox(height: 10),
            _tile(
              Icons.menu_book_outlined,
              'Trade subject',
              tradeSubject,
              Colors.purple,
              empty: 'Not picked — tap Change to set it',
              warn: tradeSubject == null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _subjects(AdminStudentDetailModel s) {
    return _card(
      title: 'Subjects',
      icon: Icons.menu_book_outlined,
      trailing: _count(s.subjects.length),
      child: s.subjects.isEmpty
          ? _emptyLine(
              Icons.menu_book_outlined,
              'No subjects yet. Subjects come from the class, department '
              'and trade.',
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < s.subjects.length; i++)
                  _subjectChip(
                    s.subjects[i].subjectName,
                    s.subjects[i].code,
                    StudentColors.accents[i % StudentColors.accents.length],
                  ),
              ],
            ),
    );
  }

  Widget _subjectChip(String name, String? code, Color color) {
    final c = _clean(code);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (c != null) ...[
            Text(
              c,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            name,
            style: const TextStyle(
              color: textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // RESULTS
  // ================================================================

  Widget _results(AdminStudentDetailModel s) {
    if (s.results.isEmpty) {
      return _emptyCard(
        Icons.assessment_outlined,
        'No results yet',
        'Scores show here once teachers enter them.',
      );
    }

    final results = [...s.results]..sort((a, b) => b.score.compareTo(a.score));
    final finished = results.where((r) => r.examScore > 0).toList();
    final average = finished.isEmpty
        ? 0.0
        : finished.fold<double>(0, (t, r) => t + r.score) / finished.length;
    final best = finished.isEmpty ? null : finished.first;
    final weakest = finished.length < 2 ? null : finished.last;

    return Column(
      children: [
        SoftCard(
          child: Row(
            children: [
              ProgressRing(
                value: average / 100,
                size: 76,
                stroke: 8,
                color: studentGradeColor(studentGradeFor(average)),
                trackColor: Colors.grey.shade200,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      finished.isEmpty ? '—' : studentFmt(average),
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'avg',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _miniStat(
                      Icons.emoji_events_outlined,
                      'Best',
                      best == null
                          ? '—'
                          : '${best.subjectName} · ${studentFmt(best.score)}',
                      Colors.green.shade600,
                    ),
                    const SizedBox(height: 8),
                    _miniStat(
                      Icons.trending_down_rounded,
                      'Needs help',
                      weakest == null
                          ? '—'
                          : '${weakest.subjectName} · ${studentFmt(weakest.score)}',
                      Colors.orange.shade700,
                    ),
                    const SizedBox(height: 8),
                    _miniStat(
                      Icons.hourglass_bottom_rounded,
                      'Exam pending',
                      '${results.length - finished.length} subject'
                          '${results.length - finished.length == 1 ? '' : 's'}',
                      Colors.blueGrey,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final r in results) ...[
          _resultCard(
            subject: _clean(r.subjectName) ?? 'Subject',
            session: _clean(r.session),
            term: _clean(r.term),
            test: r.testScore,
            exam: r.examScore,
            total: r.score,
            grade: _clean(r.grade),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _miniStat(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          '$label  ',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _resultCard({
    required String subject,
    required String? session,
    required String? term,
    required double test,
    required double exam,
    required double total,
    required String? grade,
  }) {
    final examDone = exam > 0;
    final g = grade ?? (examDone ? studentGradeFor(total) : null);
    final color = examDone ? studentGradeColor(g) : Colors.blueGrey;
    final termLabel = term == null
        ? null
        : term.toLowerCase().contains('term')
        ? term
        : 'Term $term';

    return SoftCard(
      padding: const EdgeInsets.all(14),
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
                        color: textDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (session != null || termLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        [session, termLabel].whereType<String>().join(' · '),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                examDone ? studentFmt(total) : studentFmt(test),
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                examDone ? '/100' : '/40',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
              const SizedBox(width: 10),
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  examDone ? (g ?? '—') : '…',
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Expanded(
                    flex: (test.clamp(0, 40) * 10).round().clamp(0, 400),
                    child: Container(color: Colors.blue.shade400),
                  ),
                  Expanded(
                    flex: (40 - test.clamp(0, 40)).round() * 10,
                    child: Container(color: Colors.blue.shade50),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (exam.clamp(0, 60) * 10).round().clamp(0, 600),
                    child: Container(color: Colors.purple.shade400),
                  ),
                  Expanded(
                    flex: (60 - exam.clamp(0, 60)).round() * 10,
                    child: Container(color: Colors.purple.shade50),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _legendDot(Colors.blue.shade400, 'Test ${studentFmt(test)}/40'),
              const SizedBox(width: 14),
              examDone
                  ? _legendDot(
                      Colors.purple.shade400,
                      'Exam ${studentFmt(exam)}/60',
                    )
                  : _legendDot(Colors.orange, 'Exam not entered yet'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String text) {
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
  // TASKS
  // ================================================================

  Widget _tasks(AdminStudentDetailModel s) {
    if (s.assignments.isEmpty) {
      return _emptyCard(
        Icons.assignment_outlined,
        'No assignments',
        'Assignments teachers give this class will show here.',
      );
    }

    final tasks = [...s.assignments]
      ..sort((a, b) {
        final ad = a.dueDate, bd = b.dueDate;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return bd.compareTo(ad);
      });

    return Column(
      children: [
        for (var i = 0; i < tasks.length; i++) ...[
          _taskCard(
            tasks[i],
            StudentColors.accents[i % StudentColors.accents.length],
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _taskCard(AdminStudentAssignmentModel a, Color accent) {
    final due = a.dueDate;
    final days = due == null ? null : studentDaysFromToday(due);

    final (String dueText, Color dueColor) = switch (days) {
      null => ('No due date', Colors.grey),
      < 0 => ('Closed ${_date(due!)}', Colors.grey.shade600),
      0 => ('Due today', Colors.red.shade600),
      1 => ('Due tomorrow', Colors.orange.shade800),
      final int d when d <= 7 => ('Due in $d days', Colors.orange.shade800),
      _ => ('Due ${_date(due!)}', Colors.green.shade700),
    };

    final description = _clean(a.description);
    final teacher = _clean(a.teacherName);

    return SoftCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.subjectName,
                            style: TextStyle(
                              color: accent,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _pill(
                          a.isPublished ? 'Published' : 'Draft',
                          a.isPublished ? Colors.green.shade700 : Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 14, color: dueColor),
                        const SizedBox(width: 4),
                        Text(
                          dueText,
                          style: TextStyle(
                            color: dueColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (teacher != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              teacher,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // PARENTS
  // ================================================================

  Widget _parents(AdminStudentDetailModel s) {
    if (s.parents.isEmpty) {
      return _emptyCard(
        Icons.family_restroom_outlined,
        'No parent linked',
        'Link a parent from the Parents page so they can follow this '
            "student's progress.",
        action: OutlinedButton.icon(
          onPressed: () => context.push('/admin/${widget.schoolId}/parents'),
          icon: const Icon(Icons.link_rounded, size: 18),
          label: const Text('Go to Parents'),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < s.parents.length; i++) ...[
          _parentCard(
            s.parents[i],
            StudentColors.accents[i % StudentColors.accents.length],
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _parentCard(AdminStudentParentModel p, Color color) {
    final name = _clean(p.parentName) ?? 'Parent / guardian';
    final email = _clean(p.email);
    final phone = _clean(p.phoneNumber);

    return SoftCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  studentInitials(name, fallback: 'P'),
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
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
                      name,
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
                      'Parent / guardian',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (email != null || phone != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (email != null)
                  Expanded(
                    child: _contactButton(
                      Icons.alternate_email_rounded,
                      email,
                      () => _copy(email, 'Email'),
                    ),
                  ),
                if (email != null && phone != null) const SizedBox(width: 8),
                if (phone != null)
                  Expanded(
                    child: _contactButton(
                      Icons.phone_outlined,
                      phone,
                      () => _copy(phone, 'Phone'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _contactButton(IconData icon, String text, VoidCallback onTap) {
    return Material(
      color: StudentColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 15, color: primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.copy_rounded, size: 13, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // FALLBACK (details failed, list row available)
  // ================================================================

  Widget _basicOverview(AdminStudentModel b) {
    final level = _clean(b.schoolLevel) ?? _classType(b.className ?? '');

    return _card(
      title: 'What we know',
      icon: Icons.person_outline_rounded,
      child: Column(
        children: [
          _infoRow(
            Icons.class_outlined,
            'Class',
            _clean(b.className) ?? 'No class',
          ),
          _divider(),
          _infoRow(Icons.layers_outlined, 'Level', level),
          _divider(),
          _infoRow(
            Icons.account_tree_outlined,
            'Department',
            _clean(b.departmentName) ?? '—',
          ),
          _divider(),
          _infoRow(
            Icons.construction_outlined,
            'Trade',
            _clean(b.tradeName) ?? '—',
          ),
          _divider(),
          _infoRow(
            Icons.family_restroom_outlined,
            'Parents',
            '${b.parentCount}',
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(Object error) {
    final info = _describe(error);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade800,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Full profile couldn't load",
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info.message,
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _refresh,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 17),
                label: const Text('Try again'),
              ),
              const SizedBox(width: 8),
              if (info.parseBug || kDebugMode)
                TextButton(
                  onPressed: () => _showTechnical(error),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange.shade900,
                  ),
                  child: const Text('Technical details'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTechnical(Object error) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Technical details'),
        content: SingleChildScrollView(
          child: SelectableText(
            error.toString(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _copy(error.toString(), 'Error'),
            child: const Text('Copy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _fullError(Object error) {
    final info = _describe(error);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(30, 90, 30, 30),
      children: [
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_off_outlined,
              color: Colors.red.shade400,
              size: 34,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Unable to load student',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textDark,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          info.message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: _refresh,
            style: FilledButton.styleFrom(backgroundColor: primary),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
          ),
        ),
        if (info.parseBug || kDebugMode)
          Center(
            child: TextButton(
              onPressed: () => _showTechnical(error),
              child: const Text('Technical details'),
            ),
          ),
      ],
    );
  }

  // ================================================================
  // LOADING
  // ================================================================

  Widget _loadingView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
      children: [
        const Shimmer(
          child: ShimmerBox(width: double.infinity, height: 220, radius: 24),
        ),
        const SizedBox(height: 14),
        _sectionShimmer(),
      ],
    );
  }

  Widget _sectionShimmer() {
    return Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                ShimmerBox(width: i == 0 ? 90 : 76, height: 36, radius: 20),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 14),
          const ShimmerBox(width: double.infinity, height: 150, radius: 18),
          const SizedBox(height: 12),
          const ShimmerBox(width: double.infinity, height: 210, radius: 18),
        ],
      ),
    );
  }

  // ================================================================
  // SMALL PIECES
  // ================================================================

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon, color: primary, size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _tile(
    IconData icon,
    String label,
    String? value,
    Color color, {
    required String empty,
    bool warn = false,
  }) {
    final has = value != null;
    final c = warn ? Colors.red.shade400 : (has ? color : Colors.grey);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: warn
            ? Colors.red.shade50
            : has
            ? color.withValues(alpha: .06)
            : StudentColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: c),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ?? empty,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: has ? textDark : c,
                    fontSize: 13,
                    fontWeight: has ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onCopy,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onCopy != null)
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Copy',
            onPressed: onCopy,
            icon: Icon(
              Icons.copy_rounded,
              size: 16,
              color: Colors.grey.shade500,
            ),
          ),
      ],
    );
  }

  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Divider(height: 1, color: Colors.grey.shade200),
  );

  Widget _count(int n) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: StudentColors.primaryLight,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      '$n',
      style: const TextStyle(
        color: primary,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _emptyLine(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudentColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(
    IconData icon,
    String title,
    String message, {
    Widget? action,
  }) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        children: [
          IconBadge(icon, color: primary, size: 60, circle: true),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: textDark,
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 14), action],
        ],
      ),
    );
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _date(DateTime d) {
    final l = d.toLocal();
    return '${l.day} ${_months[l.month - 1]} ${l.year}';
  }

  String _classType(String className) {
    final name = className.toLowerCase().trim();
    if (name.isEmpty) return 'Unknown';

    final senior =
        RegExp(r'\byear\s*(10|11|12)\b').hasMatch(name) ||
        RegExp(r'\b(ss|sss)\s*[1-3]\b').hasMatch(name) ||
        name.contains('senior');
    if (senior) return 'Senior';

    final junior =
        name.contains('junior') ||
        RegExp(r'\bjss\s*[1-3]\b').hasMatch(name) ||
        RegExp(r'\byear\s*[1-9]\b').hasMatch(name);
    if (junior) return 'Junior';

    return 'Unknown';
  }
}

// ==================================================================
// ASSIGN / CHANGE / REMOVE TRADE SHEET
// ==================================================================
// Pops with a success message, or null if cancelled.

class _TradeSheet extends ConsumerStatefulWidget {
  const _TradeSheet({
    required this.student,
    required this.trades,
    required this.subjects,
  });

  final AdminStudentDetailModel student;
  final List<({String id, String name})> trades;
  final List<({String id, String name, String tradeId})> subjects;

  @override
  ConsumerState<_TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState extends ConsumerState<_TradeSheet> {
  static const Color primary = StudentColors.primary;

  String? _tradeId;
  String? _subjectId;
  bool _saving = false;
  bool _removing = false;
  String? _error;

  bool get _hasTrade =>
      widget.student.tradeId != null &&
      widget.student.tradeId!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final current = widget.student.tradeId;
    if (widget.trades.any((t) => t.id == current)) {
      _tradeId = current;
      final subject = widget.student.tradeSubjectId;
      if (widget.subjects.any((s) => s.id == subject && s.tradeId == current)) {
        _subjectId = subject;
      }
    }
  }

  String _message(Object e) {
    final text = e
        .toString()
        .replaceFirst(RegExp(r'^[A-Za-z]*Exception(\s*\[[^\]]*\])?:\s*'), '')
        .trim();
    return text.isEmpty ? 'Something went wrong.' : text;
  }

  Future<void> _save() async {
    if (_tradeId == null || _subjectId == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(adminStudentProvider.notifier)
          .assignStudentToTrade(
            studentId: widget.student.studentId,
            tradeId: _tradeId!,
            tradeSubjectId: _subjectId!,
          );

      if (!mounted) return;

      if (result != null) {
        Navigator.of(
          context,
        ).pop(_hasTrade ? 'Trade changed successfully' : 'Trade assigned');
      } else {
        setState(() {
          _saving = false;
          _error = 'Unable to save the trade. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _message(e);
      });
    }
  }

  Future<void> _remove() async {
    setState(() {
      _removing = true;
      _error = null;
    });

    try {
      final result = await ref
          .read(adminStudentProvider.notifier)
          .unassignStudentFromTrade(studentId: widget.student.studentId);

      if (!mounted) return;

      if (result == true) {
        Navigator.of(context).pop('Trade removed');
      } else {
        setState(() {
          _removing = false;
          _error = 'Unable to remove the trade. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _removing = false;
        _error = _message(e);
      });
    }
  }

  InputDecoration _decoration(String hint, IconData icon) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c, width: w),
    );

    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: primary, size: 20),
      filled: true,
      fillColor: StudentColors.background,
      border: border(Colors.transparent),
      enabledBorder: border(Colors.transparent),
      focusedBorder: border(primary, 1.4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = _saving || _removing;
    final subjects = widget.subjects
        .where((s) => s.tradeId == _tradeId)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetHandle(),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const IconBadge(
                      Icons.construction_outlined,
                      color: Colors.deepOrange,
                      size: 46,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _hasTrade ? 'Change trade' : 'Assign trade',
                            style: const TextStyle(
                              color: StudentColors.textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.student.studentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Trade',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _tradeId,
                  isExpanded: true,
                  borderRadius: BorderRadius.circular(14),
                  decoration: _decoration(
                    'Select trade',
                    Icons.construction_outlined,
                  ),
                  items: [
                    for (final t in widget.trades)
                      DropdownMenuItem(
                        value: t.id,
                        child: Text(t.name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: busy
                      ? null
                      : (v) => setState(() {
                          _tradeId = v;
                          _subjectId = null;
                        }),
                ),
                if (_tradeId != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Trade subject',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    // New key per trade so the old subject never lingers.
                    key: ValueKey('subject-$_tradeId'),
                    initialValue: _subjectId,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(14),
                    decoration: _decoration(
                      subjects.isEmpty
                          ? 'No subjects in this trade'
                          : 'Select trade subject',
                      Icons.menu_book_outlined,
                    ),
                    items: [
                      for (final s in subjects)
                        DropdownMenuItem(
                          value: s.id,
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: busy || subjects.isEmpty
                        ? null
                        : (v) => setState(() => _subjectId = v),
                  ),
                  if (subjects.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Create a subject for this trade first (Subjects → Add, '
                      'type "Trade").',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: busy || _tradeId == null || _subjectId == null
                        ? null
                        : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      disabledBackgroundColor: primary.withValues(alpha: .35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _hasTrade ? 'Save change' : 'Assign trade',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (_hasTrade)
                      TextButton.icon(
                        onPressed: busy ? null : _remove,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                        ),
                        icon: _removing
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red.shade600,
                                ),
                              )
                            : const Icon(Icons.remove_circle_outline, size: 18),
                        label: const Text('Remove trade'),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
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
}
