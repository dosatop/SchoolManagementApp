import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TeacherAssignmentDetailsPage extends ConsumerStatefulWidget {
  const TeacherAssignmentDetailsPage({super.key, required this.assignmentId});

  final String assignmentId;

  @override
  ConsumerState<TeacherAssignmentDetailsPage> createState() =>
      _TeacherAssignmentDetailsPageState();
}

class _TeacherAssignmentDetailsPageState
    extends ConsumerState<TeacherAssignmentDetailsPage> {
  bool _showMissing = false;

  Future<void> _refresh() async {
    final id = widget.assignmentId.trim();
    if (id.isEmpty || id == 'null') return;

    ref.invalidate(teacherAssignmentDetailsProvider(id));

    await sSafe(ref.read(teacherAssignmentDetailsProvider(id).future));
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.assignmentId.trim();
    final invalidId = id.isEmpty || id == 'null';

    final async = invalidId
        ? null
        : ref.watch(teacherAssignmentDetailsProvider(id));

    final assignment = _extract(async?.valueOrNull);

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar(
        'Assignment',
        subtitle: sStr(assignment, ['title']),
        actions: [
          if (!invalidId)
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: StudentColors.primary,
        onRefresh: _refresh,
        child: Builder(
          builder: (context) {
            if (invalidId) {
              return const StudentEmptyView(
                icon: Icons.link_off_rounded,
                title: 'Assignment not found',
                message: 'Go back and open the assignment again.',
              );
            }

            if (async!.isLoading && !async.hasValue) {
              return const StudentLoadingView(layout: LoadingLayout.detail);
            }

            if (async.hasError && !async.hasValue) {
              return StudentErrorView(
                error: async.error!,
                onRetry: _refresh,
                title: 'Unable to load assignment',
              );
            }

            if (assignment == null) {
              return const StudentEmptyView(
                icon: Icons.assignment_outlined,
                title: 'Assignment not found',
                message: 'The assignment may have been deleted.',
              );
            }

            return _content(assignment);
          },
        ),
      ),
    );
  }

  // ================================================================
  // ASSIGNMENT CONTENT
  // ================================================================

  Widget _content(Map assignment) {
    final title = sStr(assignment, ['title', 'name']) ?? 'Untitled assignment';

    final description = sStr(assignment, ['description']);
    final subject = sStr(assignment, ['subjectName', 'subject']);
    final className = sStr(assignment, ['className', 'class']);
    final classId = sStr(assignment, ['classId']);
    final session = sStr(assignment, ['session']);
    final term = sStr(assignment, ['term']);
    final assignedAt = sLocal(assignment, ['assignedAt', 'createdAt']);
    final due = sLocal(assignment, ['dueDate', 'deadline']);
    final isPublished = assignment['isPublished'] != false;

    final rawAttachment = sStr(assignment, ['attachmentUrl']);
    final attachment = rawAttachment == null || rawAttachment == 'string'
        ? null
        : rawAttachment;

    final submissions = sList(assignment['submissions']);

    final classStudents = classId == null
        ? <dynamic>[]
        : sList(ref.watch(teacherStudentsProvider(classId)).valueOrNull, [
            'students',
          ]);

    final submittedIds = submissions
        .map((s) => sStr(s, ['studentId']))
        .whereType<String>()
        .toSet();

    final missing = classStudents.where((student) {
      final studentId = sStr(student, ['studentId', 'id']);
      return studentId != null && !submittedIds.contains(studentId);
    }).toList();

    final graded = submissions.where((s) {
      return s is Map && (s['isGraded'] == true || sNum(s, ['score']) != null);
    }).length;

    final now = DateTime.now();
    final status = !isPublished
        ? 'Draft'
        : due != null && due.isBefore(now)
        ? 'Closed'
        : 'Open';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      children: [
        // HEADER
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [StudentColors.primary, Color(0xFF2437C5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _headerPill(
                    status == 'Draft'
                        ? Icons.visibility_off_outlined
                        : status == 'Closed'
                        ? Icons.lock_outline_rounded
                        : Icons.radio_button_checked_rounded,
                    status,
                  ),
                  const Spacer(),
                  if (due != null)
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _headerPill(Icons.event_outlined, _dueText(due)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subject != null || className != null) ...[
                const SizedBox(height: 8),
                Text(
                  [
                    if (subject != null) subject,
                    if (className != null) className,
                  ].join(' · '),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SummaryStat('Submitted', '${submissions.length}'),
                  ),
                  Expanded(child: SummaryStat('Graded', '$graded')),
                  Expanded(
                    child: SummaryStat(
                      'Not yet',
                      classStudents.isEmpty ? '—' : '${missing.length}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // INSTRUCTIONS
        const SizedBox(height: 20),
        _title('Instructions'),
        const SizedBox(height: 10),
        _card(
          Padding(
            padding: const EdgeInsets.all(15),
            child: Text(
              description ?? 'No instructions provided.',
              style: TextStyle(
                color: description == null
                    ? Colors.grey.shade500
                    : StudentColors.textDark,
                fontSize: 14,
                height: 1.55,
              ),
            ),
          ),
        ),

        // ATTACHMENT
        if (attachment != null) ...[
          const SizedBox(height: 20),
          _title('Attachment'),
          const SizedBox(height: 10),
          _card(
            ListTile(
              leading: _iconBox(
                Icons.insert_drive_file_outlined,
                Colors.orange,
              ),
              title: Text(
                attachment,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
              ),
              trailing: IconButton(
                tooltip: 'Copy link',
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => _copy(attachment),
              ),
            ),
          ),
        ],

        // DETAILS
        const SizedBox(height: 20),
        _title('Details'),
        const SizedBox(height: 10),
        _card(
          Column(
            children: _divided([
              if (due != null)
                _infoRow(
                  Icons.event_outlined,
                  'Due',
                  _dateTime(due),
                  Colors.red,
                ),
              if (assignedAt != null)
                _infoRow(
                  Icons.access_time_rounded,
                  'Assigned',
                  _dateTime(assignedAt),
                  Colors.green,
                ),
              if (term != null || session != null)
                _infoRow(
                  Icons.school_outlined,
                  'Term',
                  [term, session].whereType<String>().join(' · '),
                  Colors.purple,
                ),
              _infoRow(
                isPublished
                    ? Icons.check_circle_outline
                    : Icons.visibility_off_outlined,
                'Visibility',
                isPublished
                    ? 'Published to students'
                    : 'Draft — students cannot see it',
                isPublished ? Colors.teal : Colors.grey,
              ),
            ]),
          ),
        ),

        // SUBMISSIONS
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _title('Submissions')),
            if (classStudents.isNotEmpty)
              Text(
                '${submissions.length} of ${classStudents.length}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
          ],
        ),
        if (classStudents.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: classStudents.isEmpty
                  ? 0
                  : (submissions.length / classStudents.length)
                        .clamp(0.0, 1.0)
                        .toDouble(),
              minHeight: 7,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
        ],
        const SizedBox(height: 10),

        if (submissions.isEmpty)
          _card(
            const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.inbox_outlined, color: Colors.orange, size: 28),
                  SizedBox(width: 12),
                  Expanded(child: Text('No submissions yet.')),
                ],
              ),
            ),
          )
        else
          _card(
            Column(
              children: _divided([
                for (final submission in submissions)
                  _submissionRow(submission),
              ]),
            ),
          ),

        // STUDENTS WHO HAVE NOT SUBMITTED
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 14),
          _card(
            Column(
              children: [
                ListTile(
                  onTap: () {
                    setState(() => _showMissing = !_showMissing);
                  },
                  leading: _iconBox(Icons.hourglass_empty_rounded, Colors.red),
                  title: Text(
                    '${missing.length} student${missing.length == 1 ? '' : 's'} not submitted',
                    style: const TextStyle(
                      color: StudentColors.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: Icon(
                    _showMissing
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                  ),
                ),
                if (_showMissing)
                  for (final student in missing) ...[
                    Divider(height: 1, color: Colors.grey.shade200),
                    ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 15,
                        child: Text(
                          _initials(
                            sStr(student, [
                                  'studentName',
                                  'fullName',
                                  'name',
                                ]) ??
                                'Student',
                          ),
                        ),
                      ),
                      title: Text(
                        sStr(student, ['studentName', 'fullName', 'name']) ??
                            'Student',
                      ),
                      subtitle: sStr(student, ['studentNumber']) == null
                          ? null
                          : Text('No. ${sStr(student, ['studentNumber'])}'),
                    ),
                  ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ================================================================
  // SUBMISSION ROW
  // ================================================================

  Widget _submissionRow(dynamic submission) {
    final name =
        sStr(submission, ['studentName', 'fullName', 'name']) ??
        sStr(submission is Map ? submission['student'] : null, [
          'fullName',
          'studentName',
        ]) ??
        'Student';

    final studentNumber = sStr(submission, ['studentNumber']);
    final submittedAt = sLocal(submission, ['submittedAt', 'createdAt']);
    final score = sNum(submission, ['score']);

    final isGraded =
        submission is Map && (submission['isGraded'] == true || score != null);

    return InkWell(
      onTap: () => _showSubmission(submission, name),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: StudentColors.primaryLight,
              child: Text(
                _initials(name),
                style: const TextStyle(
                  color: StudentColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
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
                    style: const TextStyle(
                      color: StudentColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (studentNumber != null)
                    Text(
                      'Student No. $studentNumber',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  if (submittedAt != null)
                    Text(
                      'Submitted ${_dateTime(submittedAt)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (isGraded && score != null) ...[
              Text(
                '${_fmt(score)}/10',
                style: const TextStyle(
                  color: StudentColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: isGraded
                    ? Colors.green.withValues(alpha: 0.10)
                    : Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isGraded ? 'Graded' : 'Not graded',
                style: TextStyle(
                  color: isGraded
                      ? Colors.green.shade700
                      : Colors.orange.shade800,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // OPEN GRADING SHEET
  // ================================================================

  Future<void> _showSubmission(dynamic submission, String name) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubmissionGradingSheet(
        assignmentId: widget.assignmentId,
        submission: submission,
        studentName: name,
      ),
    );

    if (!mounted || saved != true) return;

    final id = widget.assignmentId.trim();

    ref.invalidate(teacherAssignmentDetailsProvider(id));

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Assignment graded successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ================================================================
  // SMALL WIDGETS
  // ================================================================

  Widget _headerPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(String text) => Text(
    text,
    style: const TextStyle(
      color: StudentColors.textDark,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  );

  Widget _card(Widget child) => Container(
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: child,
  );

  Widget _iconBox(IconData icon, Color color) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(11),
    ),
    child: Icon(icon, color: color, size: 20),
  );

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _iconBox(icon, color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: StudentColors.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _divided(List<Widget> items) => [
    for (var i = 0; i < items.length; i++) ...[
      if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
      items[i],
    ],
  ];

  // ================================================================
  // HELPERS
  // ================================================================

  Map? _extract(dynamic data) {
    if (data is! Map) return null;

    bool looksLikeAssignment(Map value) =>
        value.containsKey('title') ||
        value.containsKey('assignmentId') ||
        (value.containsKey('id') && value.containsKey('dueDate'));

    for (final candidate in [
      data['assignment'],
      if (data['data'] is Map) (data['data'] as Map)['assignment'],
      data['data'],
      data,
    ]) {
      if (candidate is Map && looksLikeAssignment(candidate)) {
        return candidate;
      }
    }

    return null;
  }

  void _copy(String value) {
    Clipboard.setData(ClipboardData(text: value));

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          content: Text('Link copied'),
        ),
      );
  }

  String _dueText(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final days = dueDay.difference(today).inDays;

    if (days < 0) return 'Closed ${sShortDate(due)}';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';

    return 'Due ${sShortDate(due)}';
  }

  String _dateTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${sPrettyDate(date)} · $hour:$minute $period';
  }

  String _fmt(num number) =>
      number % 1 == 0 ? number.toInt().toString() : number.toStringAsFixed(1);

  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

// ==================================================================
// SEPARATE GRADING SHEET
// Its controllers are disposed with this widget, even when Android
// Back closes the modal.
// ==================================================================

class _SubmissionGradingSheet extends ConsumerStatefulWidget {
  const _SubmissionGradingSheet({
    required this.assignmentId,
    required this.submission,
    required this.studentName,
  });

  final String assignmentId;
  final dynamic submission;
  final String studentName;

  @override
  ConsumerState<_SubmissionGradingSheet> createState() =>
      _SubmissionGradingSheetState();
}

class _SubmissionGradingSheetState
    extends ConsumerState<_SubmissionGradingSheet> {
  late final TextEditingController _scoreController;
  late final TextEditingController _feedbackController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final existingScore = _value(['score']);
    final existingFeedback = _value(['feedback']);

    _scoreController = TextEditingController(
      text: existingScore?.toString() ?? '',
    );

    _feedbackController = TextEditingController(
      text: existingFeedback?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  dynamic _value(List<String> keys) {
    final submission = widget.submission;

    if (submission is! Map) return null;

    for (final key in keys) {
      if (submission[key] != null) {
        return submission[key];
      }
    }

    return null;
  }

  String _stringValue(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  Future<void> _copyAttachment(String url) async {
    await Clipboard.setData(ClipboardData(text: url));

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Attachment link copied'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _saveGrade() async {
    if (_isSaving) return;

    final scoreText = _scoreController.text.trim();
    final feedbackText = _feedbackController.text.trim();
    final enteredScore = double.tryParse(scoreText);

    if (enteredScore == null ||
        !enteredScore.isFinite ||
        enteredScore < 0 ||
        enteredScore > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid score from 0 to 10.')),
      );
      return;
    }

    final submissionId = _stringValue(
      _value(['submissionId', 'id', 'studentAssignmentId']),
    );

    if (submissionId.isEmpty || submissionId == 'null') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot grade this submission: submission ID is missing.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final success = await ref
          .read(teachersProvider.notifier)
          .gradeSubmission(
            assignmentId: widget.assignmentId,
            submissionId: submissionId,
            score: enteredScore,
            feedback: feedbackText.isEmpty ? null : feedbackText,
          );

      // Android Back may have disposed this sheet during the request.
      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save the grade. Please try again.'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save grade: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final answer = _stringValue(
      _value(['submissionText', 'text', 'answer', 'textAnswer', 'content']),
    );

    final attachment = _stringValue(
      _value(['attachmentUrl', 'fileUrl', 'documentUrl', 'imageUrl']),
    );

    final score = _value(['score']);
    final isGraded = _value(['isGraded']) == true || score != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: .78,
        minChildSize: .45,
        maxChildSize: .95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.studentName,
                          style: const TextStyle(
                            color: StudentColors.textDark,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          score == null
                              ? 'Not graded yet'
                              : 'Current score: $score/10',
                          style: TextStyle(
                            color: isGraded
                                ? Colors.green.shade700
                                : Colors.orange.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Student answer
              const Text(
                'Student answer',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: StudentColors.textDark,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: StudentColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SelectableText(
                  answer.isEmpty ? 'No written answer.' : answer,
                  style: const TextStyle(height: 1.5),
                ),
              ),

              if (attachment.isNotEmpty && attachment != 'string') ...[
                const SizedBox(height: 16),
                const Text(
                  'Student attachment',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: StudentColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  attachment,
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _copyAttachment(attachment),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy attachment link'),
                  ),
                ),
              ],

              // Grading form
              const SizedBox(height: 22),
              const Text(
                'Grade submission',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: StudentColors.textDark,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Enter a score from 0 to 10. You can update the grade later.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _scoreController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  labelText: 'Score (out of 10)',
                  hintText: 'e.g. 8.5',
                  prefixIcon: const Icon(Icons.grade_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _feedbackController,
                enabled: !_isSaving,
                maxLines: 4,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Feedback (optional)',
                  hintText: 'Give the student feedback...',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.comment_outlined),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveGrade,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving
                        ? 'Saving grade...'
                        : score == null
                        ? 'Save grade'
                        : 'Update grade',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: StudentColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
