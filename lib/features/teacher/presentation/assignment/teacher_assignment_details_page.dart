import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==================================================================
// TEACHER: ASSIGNMENT DETAILS
// ==================================================================
// Accepts the assignment in any of these shapes:
//   { assignmentId | id, title, ... }
//   { assignment: {...} }   { data: {...} }   { data: { assignment } }
//
// Shows: title, subject/class, status, due date, description,
// attachment, and submissions — who submitted (score / graded) and,
// when the class list loads, who hasn't submitted yet.

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
    ref.invalidate(teacherAssignmentDetailsProvider(widget.assignmentId));
    await sSafe(
      ref.read(teacherAssignmentDetailsProvider(widget.assignmentId).future),
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final id = widget.assignmentId.trim();
    final invalidId = id.isEmpty || id == 'null';

    final async = invalidId
        ? null
        : ref.watch(teacherAssignmentDetailsProvider(widget.assignmentId));

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
        onRefresh: invalidId ? () async {} : _refresh,
        child: () {
          if (invalidId) {
            return const StudentEmptyView(
              icon: Icons.link_off_rounded,
              title: 'Assignment not found',
              message:
                  'This link has no assignment ID. Go back and open it again.',
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
              message: 'It may have been deleted.',
            );
          }

          return _content(assignment);
        }(),
      ),
    );
  }

  // ================================================================
  // CONTENT
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
    final attachment =
        (rawAttachment == null || rawAttachment == 'string') ? null : rawAttachment;

    final submissions = sList(assignment['submissions']);

    // Class list → who hasn't submitted (optional; ignored if it fails).
    final classStudents = classId == null
        ? const <dynamic>[]
        : sList(ref.watch(teacherStudentsProvider(classId)).valueOrNull,
              ['students']);

    final submittedIds = submissions
        .map((s) => sStr(s, ['studentId']))
        .whereType<String>()
        .toSet();

    final missing = classStudents
        .where((s) => !submittedIds.contains(sStr(s, ['studentId', 'id'])))
        .toList();

    final graded = submissions
        .where((s) => s is Map && (s['isGraded'] == true || s['score'] != null))
        .length;

    final now = DateTime.now();
    final status = !isPublished
        ? 'Draft'
        : (due != null && due.isBefore(now) ? 'Closed' : 'Open');

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      children: [
        // ---------------- HEADER ----------------
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
                    switch (status) {
                      'Draft' => Icons.visibility_off_outlined,
                      'Closed' => Icons.lock_outline_rounded,
                      _ => Icons.radio_button_checked_rounded,
                    },
                    status,
                  ),
                  const Spacer(),
                  if (due != null) _headerPill(Icons.event_outlined, _dueText(due)),
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
                  SummaryStat('Submitted', '${submissions.length}'),
                  SummaryStat('Graded', '$graded'),
                  SummaryStat(
                    'Not yet',
                    classStudents.isEmpty ? '—' : '${missing.length}',
                  ),
                ],
              ),
            ],
          ),
        ),

        // ---------------- DESCRIPTION ----------------
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

        // ---------------- ATTACHMENT ----------------
        if (attachment != null) ...[
          const SizedBox(height: 20),
          _title('Attachment'),
          const SizedBox(height: 10),
          _card(
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              leading: _iconBox(Icons.insert_drive_file_outlined, Colors.orange),
              title: Text(
                attachment,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
              ),
              trailing: IconButton(
                tooltip: 'Copy link',
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () => _copy(attachment),
              ),
            ),
          ),
        ],

        // ---------------- DETAILS ----------------
        const SizedBox(height: 20),
        _title('Details'),
        const SizedBox(height: 10),
        _card(
          Column(
            children: _divided([
              if (due != null)
                _infoRow(Icons.event_outlined, 'Due', _dateTime(due), Colors.red),
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
                isPublished ? 'Published to students' : 'Draft — students can\'t see it',
                isPublished ? Colors.teal : Colors.grey,
              ),
            ]),
          ),
        ),

        // ---------------- SUBMISSIONS ----------------
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
              value: (submissions.length / classStudents.length).clamp(0, 1).toDouble(),
              minHeight: 7,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(Colors.green),
            ),
          ),
        ],
        const SizedBox(height: 10),

        if (submissions.isEmpty)
          _card(
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  _iconBox(Icons.inbox_outlined, Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No submissions yet.',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _card(
            Column(
              children: _divided([
                for (final s in submissions) _submissionRow(s),
              ]),
            ),
          ),

        // ---------------- NOT SUBMITTED ----------------
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 14),
          _card(
            Column(
              children: [
                ListTile(
                  onTap: () => setState(() => _showMissing = !_showMissing),
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
                  for (final s in missing) ...[
                    Divider(height: 1, color: Colors.grey.shade200),
                    ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.grey.shade100,
                        child: Text(
                          _initials(sStr(s, ['studentName', 'fullName', 'name']) ?? '?'),
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        sStr(s, ['studentName', 'fullName', 'name']) ?? 'Student',
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: sStr(s, ['studentNumber']) == null
                          ? null
                          : Text('No. ${sStr(s, ['studentNumber'])}'),
                    ),
                  ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _submissionRow(dynamic s) {
    final name = sStr(s, ['studentName', 'fullName', 'name']) ??
        sStr(s is Map ? s['student'] : null, ['fullName', 'studentName']) ??
        'Student';
    final submittedAt = sLocal(s, ['submittedAt', 'createdAt']);
    final score = sNum(s, ['score']);
    final isGraded = s is Map && (s['isGraded'] == true || score != null);

    return InkWell(
      onTap: () => _showSubmission(s, name),
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
                  if (submittedAt != null)
                    Text(
                      'Submitted ${_dateTime(submittedAt)}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                ],
              ),
            ),
            if (score != null) ...[
              Text(
                _fmt(score),
                style: const TextStyle(
                  color: StudentColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
            ],
            StatusChip(isGraded ? 'Graded' : 'Submitted'),
          ],
        ),
      ),
    );
  }

  void _showSubmission(dynamic s, String name) {
    final text = sStr(s, ['submissionText', 'text', 'answer']);
    final file = sStr(s, ['attachmentUrl']);
    final feedback = sStr(s, ['feedback']);
    final score = sNum(s, ['score']);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: .6,
        minChildSize: .35,
        maxChildSize: .92,
        expand: false,
        builder: (context, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            children: [
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
              Text(
                name,
                style: const TextStyle(
                  color: StudentColors.textDark,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (score != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Score: ${_fmt(score)}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Answer', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: StudentColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SelectableText(
                  text ?? 'No written answer.',
                  style: const TextStyle(height: 1.5),
                ),
              ),
              if (file != null && file != 'string') ...[
                const SizedBox(height: 14),
                const Text('File', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                SelectableText(
                  file,
                  style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                ),
              ],
              if (feedback != null) ...[
                const SizedBox(height: 14),
                const Text(
                  'Your feedback',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(feedback, style: const TextStyle(height: 1.5)),
              ],
            ],
          ),
        ),
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

  /// Finds the assignment map in any response shape.
  Map? _extract(dynamic data) {
    if (data is! Map) return null;

    bool looksLikeAssignment(Map m) =>
        m.containsKey('title') ||
        m.containsKey('assignmentId') ||
        (m.containsKey('id') && m.containsKey('dueDate'));

    for (final candidate in [
      data['assignment'],
      if (data['data'] is Map) (data['data'] as Map)['assignment'],
      data['data'],
      data,
    ]) {
      if (candidate is Map && looksLikeAssignment(candidate)) return candidate;
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
    final days = DateTime(due.year, due.month, due.day).difference(today).inDays;

    if (days < 0) return 'Closed ${sShortDate(due)}';
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    return 'Due ${sShortDate(due)}';
  }

  String _dateTime(DateTime d) {
    final hour = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final minute = d.minute.toString().padLeft(2, '0');
    final period = d.hour >= 12 ? 'PM' : 'AM';
    return '${sPrettyDate(d)} · $hour:$minute $period';
  }

  String _fmt(num n) =>
      n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}