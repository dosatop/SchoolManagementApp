import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/provider/students_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Filter { all, todo, submitted, overdue }

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

    final sorted = [...visible]..sort(_byDue);

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar('Assignments', subtitle: 'This term'),
      body: Column(
        children: [
          // ---------------- FILTER CHIPS ----------------
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('To do', todo.length, _Filter.todo),
                  _chip('Overdue', overdue.length, _Filter.overdue),
                  _chip('Submitted', submitted.length, _Filter.submitted),
                  _chip('All', all.length, _Filter.all),
                ],
              ),
            ),
          ),

          // ---------------- LIST ----------------
          Expanded(
            child: RefreshIndicator(
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
                    title: 'Unable to load assignments',
                  );
                }

                if (sorted.isEmpty) {
                  return StudentEmptyView(
                    icon: _filter == _Filter.todo
                        ? Icons.task_alt_rounded
                        : Icons.assignment_outlined,
                    title: switch (_filter) {
                      _Filter.todo => 'All caught up',
                      _Filter.overdue => 'Nothing overdue',
                      _Filter.submitted => 'Nothing submitted yet',
                      _Filter.all => 'No assignments yet',
                    },
                    message: switch (_filter) {
                      _Filter.todo => 'You have no assignments to submit.',
                      _Filter.overdue => 'Great — you are on schedule.',
                      _Filter.submitted =>
                        'Assignments you submit will show here.',
                      _Filter.all =>
                        'Assignments from your teachers will show here.',
                    },
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _card(sorted[i]),
                );
              }(),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // FILTER CHIP
  // ================================================================

  Widget _chip(String label, int count, _Filter value) {
    final selected = _filter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        showCheckmark: false,
        selectedColor: StudentColors.primary,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: selected ? StudentColors.primary : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        label: Text(
          '$label · $count',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
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
    final status = done
        ? (_isGraded(item) ? 'Graded' : 'Submitted')
        : (_isOverdue(item) ? 'Overdue' : 'To do');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openDetails(item),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
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
                        fontWeight: FontWeight.bold,
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
                    Icons.event_outlined,
                    size: 15,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    due == null ? 'No due date' : 'Due ${_dueText(due)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const Spacer(),
                  if (!done)
                    Text(
                      'Submit',
                      style: TextStyle(
                        color: StudentColors.primary.withValues(alpha: .9),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
    );
  }

  // ================================================================
  // DETAILS + SUBMIT SHEET
  // ================================================================

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

  bool _isGraded(dynamic item) {
    if (sNum(item, ['score', 'grade']) != null) return true;
    final sub = item is Map ? item['submission'] : null;
    return sNum(sub, ['score']) != null;
  }

  bool _isOverdue(dynamic item) {
    final due = sLocal(item, ['dueDate', 'deadline']);
    return due != null && due.isBefore(DateTime.now()) && !_submitted(item);
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = DateTime(due.year, due.month, due.day)
        .difference(today)
        .inDays;

    if (days == 0) return 'today';
    if (days == 1) return 'tomorrow';
    if (days == -1) return 'yesterday';
    return sPrettyDate(due);
  }
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
  void dispose() {
    _answer.dispose();
    _link.dispose();
    super.dispose();
  }

  String? get _id =>
      sStr(widget.item, ['assignmentId', 'id']);

  @override
  Widget build(BuildContext context) {
    final id = _id;

    // Load full details (description, submission) when we have an id;
    // fall back to the list item while loading or if it fails.
    final detailAsync = id == null
        ? null
        : ref.watch(studentAssignmentProvider(id));
    final data = detailAsync?.valueOrNull ?? widget.item;

    final title = sStr(data, ['title', 'name']) ?? 'Assignment';
    final subject = sStr(data, ['subjectName', 'subject']);
    final teacher = sStr(data, ['teacherName', 'teacher']);
    final description = sStr(data, ['description', 'instructions']);
    final attachment = sStr(data, ['attachmentUrl', 'attachment']);
    final due = sLocal(data, ['dueDate', 'deadline']);

    final submission = data is Map ? data['submission'] : null;
    final submittedText = sStr(submission, ['submissionText', 'text']);
    final submittedAt = sLocal(submission ?? data, ['submittedAt']);
    final score = sNum(submission ?? data, ['score']);
    final feedback = sStr(submission ?? data, ['feedback', 'teacherFeedback']);

    final isSubmitted =
        submission is Map ||
        submittedAt != null ||
        (data is Map &&
            (data['isSubmitted'] == true || data['submitted'] == true));

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: .75,
        minChildSize: .45,
        maxChildSize: .95,
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
              const SizedBox(height: 18),

              Text(
                title,
                style: const TextStyle(
                  color: StudentColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (subject != null) _infoPill(Icons.menu_book_rounded, subject),
                  if (teacher != null)
                    _infoPill(Icons.person_outline_rounded, teacher),
                  _infoPill(
                    Icons.event_outlined,
                    due == null ? 'No due date' : 'Due ${sPrettyDate(due)}',
                  ),
                ],
              ),

              if (description != null) ...[
                const SizedBox(height: 18),
                _label('Instructions'),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade800,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],

              if (attachment != null) ...[
                const SizedBox(height: 14),
                _label('Attachment'),
                const SizedBox(height: 6),
                SelectableText(
                  attachment,
                  style: const TextStyle(
                    color: StudentColors.primary,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],

              const SizedBox(height: 22),
              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: 18),

              // ---------------- SUBMITTED ----------------
              if (isSubmitted) ...[
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        submittedAt == null
                            ? 'Submitted'
                            : 'Submitted ${sPrettyDate(submittedAt)}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (score != null)
                      StatusChip('Score ${_fmt(score)}'),
                  ],
                ),
                if (submittedText != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: StudentColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      submittedText,
                      style: const TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
                if (feedback != null) ...[
                  const SizedBox(height: 14),
                  _label('Teacher feedback'),
                  const SizedBox(height: 6),
                  Text(
                    feedback,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ]
              // ---------------- SUBMIT FORM ----------------
              else ...[
                _label('Your answer'),
                const SizedBox(height: 8),
                TextField(
                  controller: _answer,
                  minLines: 4,
                  maxLines: 10,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration('Type your answer here…'),
                ),
                const SizedBox(height: 12),
                _label('Attachment link (optional)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _link,
                  keyboardType: TextInputType.url,
                  decoration: _inputDecoration('https://…'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _submitting || id == null ? null : _submit,
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
                    label: Text(_submitting ? 'Submitting…' : 'Submit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: StudentColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _submitting = true;
      _error = null;
    });

    final error = await ref
        .read(studentActionsProvider)
        .submitAssignment(
          assignmentId: _id!,
          submissionText: _answer.text,
          attachmentUrl: _link.text,
        );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _submitting = false;
        _error = error;
      });
      return;
    }

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
        content: const Text('Assignment submitted.'),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: StudentColors.textDark,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  );

  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: StudentColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: StudentColors.primary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: StudentColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
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
        borderSide: const BorderSide(color: StudentColors.primary),
      ),
    );
  }

  String _fmt(num n) => n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(1);
}