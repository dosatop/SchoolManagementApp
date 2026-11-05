import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/presentation/widgets/student_ui.dart';
import 'package:app/features/students/provider/students_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Filter { todo, overdue, submitted, all }

class StudentAssignmentsPage extends ConsumerStatefulWidget {
  const StudentAssignmentsPage({super.key});

  @override
  ConsumerState<StudentAssignmentsPage> createState() =>
      _StudentAssignmentsPageState();
}

class _StudentAssignmentsPageState
    extends ConsumerState<StudentAssignmentsPage> {
  static const _params = StudentTermParams.current;

  _Filter _filter = _Filter.todo;

  Future<void> _refresh() async {
    ref.invalidate(studentAssignmentsProvider(_params));
    await sSafe(ref.read(studentAssignmentsProvider(_params).future));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(studentAssignmentsProvider(_params));
    final all = sList(async.valueOrNull, ['assignments']);

    final todo = all.where((a) => !_submitted(a)).toList();
    final submitted = all.where(_submitted).toList();
    final overdue = todo.where(_isOverdue).toList();

    final visible = switch (_filter) {
      _Filter.all => all,
      _Filter.todo => todo,
      _Filter.submitted => submitted,
      _Filter.overdue => overdue,
    };

    // To do / overdue: soonest first. Submitted / all: newest first.
    final sorted = [...visible]
      ..sort(
        (a, b) => _filter == _Filter.todo || _filter == _Filter.overdue
            ? _byDue(a, b)
            : _byDue(b, a),
      );

    final progress = all.isEmpty ? 0.0 : submitted.length / all.length;

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar('Assignments', subtitle: 'This term'),
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
              title: 'Unable to load assignments',
            );
          }

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ---------------- SUMMARY ----------------
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
                  child: _summary(
                    total: all.length,
                    done: submitted.length,
                    todo: todo.length,
                    overdue: overdue.length,
                    progress: progress,
                  ),
                ),
              ),

              // ---------------- FILTERS (stick to top) ----------------
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedFilters(
                  child: Container(
                    color: StudentColors.background,
                    child: PillTabs<_Filter>(
                      selected: _filter,
                      onChanged: (f) => setState(() => _filter = f),
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                      tabs: [
                        PillTab(_Filter.todo, 'To do', count: todo.length),
                        PillTab(
                          _Filter.overdue,
                          'Overdue',
                          count: overdue.length,
                          color: Colors.red.shade600,
                        ),
                        PillTab(
                          _Filter.submitted,
                          'Submitted',
                          count: submitted.length,
                          color: Colors.green.shade600,
                        ),
                        PillTab(_Filter.all, 'All', count: all.length),
                      ],
                    ),
                  ),
                ),
              ),

              // ---------------- LIST ----------------
              if (sorted.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _empty(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
                  sliver: SliverList.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _card(sorted[i]),
                  ),
                ),
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
    required int total,
    required int done,
    required int todo,
    required int overdue,
    required double progress,
  }) {
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
          ProgressRing(
            value: progress,
            size: 70,
            stroke: 7,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'done',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .7),
                    fontSize: 9.5,
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
                Text(
                  total == 0
                      ? 'No assignments yet'
                      : todo == 0
                      ? 'All $total submitted 🎉'
                      : '$done of $total submitted',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    HeroStat('To do', '$todo'),
                    HeroStat('Overdue', '$overdue'),
                    HeroStat('Done', '$done'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    final (icon, title, message) = switch (_filter) {
      _Filter.todo => (
        Icons.task_alt_rounded,
        'All caught up',
        'You have no assignments to submit.',
      ),
      _Filter.overdue => (
        Icons.verified_rounded,
        'Nothing overdue',
        'Great — you are on schedule.',
      ),
      _Filter.submitted => (
        Icons.outbox_outlined,
        'Nothing submitted yet',
        'Assignments you submit will show here.',
      ),
      _Filter.all => (
        Icons.assignment_outlined,
        'No assignments yet',
        'Assignments from your teachers will show here.',
      ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconBadge(
            icon,
            color: StudentColors.primary,
            size: 74,
            circle: true,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: StudentColors.textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CARD
  // ================================================================

  Widget _card(dynamic item) {
    final title = sStr(item, ['title', 'name']) ?? 'Assignment';
    final subject = sStr(item, ['subjectName', 'subject']);
    final teacher = sStr(item, ['teacherName', 'teacher']);
    final due = sLocal(item, ['dueDate', 'deadline']);
    final done = _submitted(item);
    final graded = done && _isGraded(item);
    final overdue = _isOverdue(item);

    final status = done
        ? (graded ? 'Graded' : 'Submitted')
        : (overdue ? 'Overdue' : 'To do');

    final accent = done
        ? Colors.green.shade600
        : overdue
        ? Colors.red.shade600
        : _dueSoon(due)
        ? Colors.orange.shade700
        : StudentColors.primary;

    final score = _score(item);

    return SoftCard(
      onTap: () => _openDetails(item),
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: StudentColors.textDark,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(status),
                      ],
                    ),
                    if (subject != null || teacher != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (subject != null) subject,
                          if (teacher != null) teacher,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: StudentColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          done
                              ? Icons.check_circle_outline_rounded
                              : Icons.schedule_rounded,
                          size: 15,
                          color: done ? Colors.green.shade600 : accent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            done
                                ? 'Submitted'
                                : due == null
                                ? 'No due date'
                                : _dueText(due),
                            style: TextStyle(
                              color: done
                                  ? Colors.green.shade700
                                  : accent == StudentColors.primary
                                  ? Colors.grey.shade600
                                  : accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (score != null)
                          Text(
                            'Score ${studentFmt(score)}',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        else if (!done)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: StudentColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey.shade400,
                          ),
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

  void _openDetails(dynamic item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignmentSheet(item: item),
    );
  }

  // ================================================================
  // HELPERS
  // ================================================================

  bool _submitted(dynamic item) {
    if (item is! Map) return false;

    for (final key in ['isSubmitted', 'submitted', 'hasSubmitted']) {
      if (item[key] == true) return true;
    }

    final status = sStr(item, ['submissionStatus', 'status'])?.toLowerCase();
    if (status == 'submitted' || status == 'graded') return true;

    return item['submission'] is Map || item['submittedAt'] != null;
  }

  num? _score(dynamic item) {
    final direct = sNum(item, ['score']);
    if (direct != null) return direct;
    final sub = item is Map ? item['submission'] : null;
    return sNum(sub, ['score']);
  }

  bool _isGraded(dynamic item) => _score(item) != null;

  bool _isOverdue(dynamic item) {
    final due = sLocal(item, ['dueDate', 'deadline']);
    return due != null && due.isBefore(DateTime.now()) && !_submitted(item);
  }

  bool _dueSoon(DateTime? due) {
    if (due == null) return false;
    final days = studentDaysFromToday(due);
    return days >= 0 && days <= 2;
  }

  int _byDue(dynamic a, dynamic b) {
    final da = sLocal(a, ['dueDate', 'deadline']);
    final db = sLocal(b, ['dueDate', 'deadline']);
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  }

  String _dueText(DateTime due) {
    final days = studentDaysFromToday(due);

    if (days < -1) return 'Was due ${sPrettyDate(due)}';
    if (days == -1) return 'Was due yesterday';
    if (days == 0) {
      final left = due.difference(DateTime.now());
      if (left.isNegative) return 'Was due today';
      if (left.inHours >= 1) return 'Due today · ${left.inHours}h left';
      return 'Due today · ${left.inMinutes}m left';
    }
    if (days == 1) return 'Due tomorrow';
    if (days <= 7) return 'Due in $days days';
    return 'Due ${sPrettyDate(due)}';
  }
}

// ==================================================================
// PINNED FILTER BAR
// ==================================================================

class _PinnedFilters extends SliverPersistentHeaderDelegate {
  _PinnedFilters({required this.child});

  final Widget child;

  @override
  double get minExtent => 58;

  @override
  double get maxExtent => 58;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_PinnedFilters old) => true;
}

// ==================================================================
// ASSIGNMENT SHEET (details + submit)
// ==================================================================

class _AssignmentSheet extends ConsumerStatefulWidget {
  const _AssignmentSheet({required this.item});

  final dynamic item;

  @override
  ConsumerState<_AssignmentSheet> createState() => _AssignmentSheetState();
}

class _AssignmentSheetState extends ConsumerState<_AssignmentSheet> {
  final _answer = TextEditingController();
  final _link = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Rebuild so the Submit button enables/disables as you type.
    _answer.addListener(_onChanged);
    _link.addListener(_onChanged);
  }

  void _onChanged() {
    if (_error != null) _error = null;
    setState(() {});
  }

  @override
  void dispose() {
    _answer.dispose();
    _link.dispose();
    super.dispose();
  }

  String? get _id => sStr(widget.item, ['assignmentId', 'id']);

  /// A link is optional, but if typed it must look like a URL.
  bool get _linkValid {
    final link = _link.text.trim();
    if (link.isEmpty) return true;
    final uri = Uri.tryParse(link);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  /// Need an answer or a link, and the link (if any) must be valid.
  bool get _canSubmit =>
      (_answer.text.trim().isNotEmpty || _link.text.trim().isNotEmpty) &&
      _linkValid;

  @override
  Widget build(BuildContext context) {
    final id = _id;

    // Full details when we have an id; fall back to the list item.
    final detailAsync = id == null
        ? null
        : ref.watch(studentAssignmentProvider(id));
    final data = detailAsync?.valueOrNull ?? widget.item;
    final loadingDetails = detailAsync?.isLoading == true &&
        detailAsync?.hasValue != true;

    final title = sStr(data, ['title', 'name']) ?? 'Assignment';
    final subject = sStr(data, ['subjectName', 'subject']);
    final teacher = sStr(data, ['teacherName', 'teacher']);
    final description = sStr(data, ['description', 'instructions']);
    final attachment = sStr(data, ['attachmentUrl', 'attachment']);
    final due = sLocal(data, ['dueDate', 'deadline']);
    final maxScore = sNum(data, ['maxScore', 'totalMarks', 'marks']);

    final submission = data is Map ? data['submission'] : null;
    final submittedText = sStr(submission, ['submissionText', 'text']);
    final submittedLink = sStr(submission, ['attachmentUrl', 'link']);
    final submittedAt = sLocal(submission ?? data, ['submittedAt']);
    final score = sNum(submission ?? data, ['score']);
    final feedback = sStr(submission ?? data, ['feedback', 'teacherFeedback']);

    final isSubmitted =
        submission is Map ||
        submittedAt != null ||
        (data is Map &&
            (data['isSubmitted'] == true || data['submitted'] == true));

    final overdue = due != null && due.isBefore(DateTime.now());

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: .8,
        minChildSize: .45,
        maxChildSize: .95,
        expand: false,
        builder: (context, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              const SheetHandle(),
              const SizedBox(height: 18),

              // ---------------- HEADER ----------------
              Row(
                children: [
                  IconBadge(
                    isSubmitted
                        ? Icons.assignment_turned_in_rounded
                        : Icons.assignment_rounded,
                    color: isSubmitted
                        ? Colors.green.shade600
                        : overdue
                        ? Colors.red.shade600
                        : StudentColors.primary,
                    size: 50,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: StudentColors.textDark,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (subject != null)
                    _infoPill(Icons.menu_book_rounded, subject),
                  if (teacher != null)
                    _infoPill(Icons.person_outline_rounded, teacher),
                  _infoPill(
                    Icons.event_outlined,
                    due == null ? 'No due date' : 'Due ${sPrettyDate(due)}',
                    color: !isSubmitted && overdue ? Colors.red.shade600 : null,
                  ),
                  if (maxScore != null)
                    _infoPill(
                      Icons.grade_outlined,
                      '${studentFmt(maxScore)} marks',
                    ),
                ],
              ),

              // ---------------- INSTRUCTIONS ----------------
              const SizedBox(height: 20),
              _label('Instructions'),
              const SizedBox(height: 8),
              if (loadingDetails && description == null)
                const Shimmer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: double.infinity, height: 12),
                      SizedBox(height: 8),
                      ShimmerBox(width: double.infinity, height: 12),
                      SizedBox(height: 8),
                      ShimmerBox(width: 180, height: 12),
                    ],
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: StudentColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    description ?? 'No instructions were added.',
                    style: TextStyle(
                      color: description == null
                          ? Colors.grey.shade500
                          : Colors.grey.shade800,
                      fontSize: 13.5,
                      height: 1.55,
                    ),
                  ),
                ),

              if (attachment != null) ...[
                const SizedBox(height: 14),
                _label('Attachment'),
                const SizedBox(height: 8),
                _linkTile(attachment),
              ],

              const SizedBox(height: 22),
              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: 18),

              // ---------------- SUBMITTED ----------------
              if (isSubmitted) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green.shade600,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Submitted',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (submittedAt != null)
                              Text(
                                sPrettyDate(submittedAt),
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (score != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              maxScore == null
                                  ? studentFmt(score)
                                  : '${studentFmt(score)}/${studentFmt(maxScore)}',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Score',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (submittedText != null) ...[
                  const SizedBox(height: 16),
                  _label('Your answer'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: StudentColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      submittedText,
                      style: const TextStyle(fontSize: 13.5, height: 1.5),
                    ),
                  ),
                ],
                if (submittedLink != null) ...[
                  const SizedBox(height: 12),
                  _linkTile(submittedLink),
                ],
                if (feedback != null) ...[
                  const SizedBox(height: 16),
                  _label('Teacher feedback'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: StudentColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.format_quote_rounded,
                          color: StudentColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feedback,
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontSize: 13.5,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ]
              // ---------------- SUBMIT FORM ----------------
              else ...[
                if (overdue)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This assignment is past its due date. Your '
                            'teacher may not accept late work.',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                _label('Your answer'),
                const SizedBox(height: 8),
                TextField(
                  controller: _answer,
                  minLines: 5,
                  maxLines: 12,
                  enabled: !_submitting,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration('Type your answer here…'),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${_answer.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length} words',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _label('Attachment link (optional)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _link,
                  enabled: !_submitting,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: _inputDecoration(
                    'https://drive.google.com/…',
                    icon: Icons.link_rounded,
                    error: _linkValid
                        ? null
                        : 'Enter a full link starting with https://',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
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
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _submitting || id == null || !_canSubmit
                        ? null
                        : _confirmAndSubmit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _submitting ? 'Submitting…' : 'Submit assignment',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StudentColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'You can\'t edit your work after submitting.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndSubmit() async {
    FocusScope.of(context).unfocus();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Submit assignment?'),
        content: const Text(
          'Once submitted, your teacher will see your answer and you '
          'won\'t be able to change it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: StudentColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (ok == true) await _submit();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    final error = await ref
        .read(studentActionsProvider)
        .submitAssignment(
          assignmentId: _id!,
          submissionText: _answer.text.trim(),
          attachmentUrl: _link.text.trim(),
        );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _submitting = false;
        _error = error;
      });
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Assignment submitted'),
          ],
        ),
      ),
    );
  }

  Widget _linkTile(String url) {
    return Material(
      color: StudentColors.primaryLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Clipboard.setData(ClipboardData(text: url));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Link copied'),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(
                Icons.link_rounded,
                color: StudentColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudentColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.copy_rounded,
                color: StudentColors.primary,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: StudentColors.textDark,
      fontSize: 13.5,
      fontWeight: FontWeight.w800,
    ),
  );

  Widget _infoPill(IconData icon, String text, {Color? color}) {
    final c = color ?? StudentColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint, {
    IconData? icon,
    String? error,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      errorText: error,
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: Colors.grey.shade500, size: 20),
      filled: true,
      fillColor: StudentColors.background,
      contentPadding: const EdgeInsets.all(14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: StudentColors.primary, width: 1.4),
      ),
    );
  }
}
