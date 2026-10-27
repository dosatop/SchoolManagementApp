import 'package:app/features/parents/parent_provider.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==================================================================
// PARENT: CHILD ASSIGNMENTS (current term, read-only)
// ==================================================================

enum _Filter { pending, overdue, submitted, all }

class ParentAssignmentsPage extends ConsumerStatefulWidget {
  const ParentAssignmentsPage({
    super.key,
    required this.studentId,
    this.header,
  });

  final String studentId;

  /// Optional widget above the content (the dashboard passes a child
  /// switcher when this page is shown as a tab).
  final Widget? header;

  @override
  ConsumerState<ParentAssignmentsPage> createState() =>
      _ParentAssignmentsPageState();
}

class _ParentAssignmentsPageState extends ConsumerState<ParentAssignmentsPage> {
  _Filter _filter = _Filter.pending;

  ParentChildTermParams get _params => ParentChildTermParams(widget.studentId);

  Future<void> _refresh() async {
    ref.invalidate(parentChildAssignmentsProvider(_params));
    await sSafe(ref.read(parentChildAssignmentsProvider(_params).future));
  }

  @override
  Widget build(BuildContext context) {
    final childAsync = ref.watch(parentChildProvider(widget.studentId));
    final async = ref.watch(parentChildAssignmentsProvider(_params));

    final all = sList(async.valueOrNull, ['assignments']);
    final submitted = all.where(_isSubmitted).toList();
    final pending = all.where((a) => !_isSubmitted(a)).toList();
    final overdue = pending.where(_isOverdue).toList();

    final visible = switch (_filter) {
      _Filter.pending => pending,
      _Filter.overdue => overdue,
      _Filter.submitted => submitted,
      _Filter.all => all,
    };

    final sorted = [...visible]..sort(_byDue);

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar(
        'Assignments',
        subtitle: childAsync.valueOrNull?.fullName,
      ),
      body: Column(
        children: [
          if (widget.header != null) widget.header!,
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('To do', pending.length, _Filter.pending),
                  _chip('Overdue', overdue.length, _Filter.overdue),
                  _chip('Submitted', submitted.length, _Filter.submitted),
                  _chip('All', all.length, _Filter.all),
                ],
              ),
            ),
          ),
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
                    icon: _filter == _Filter.pending
                        ? Icons.task_alt_rounded
                        : Icons.assignment_outlined,
                    title: switch (_filter) {
                      _Filter.pending => 'All caught up',
                      _Filter.overdue => 'Nothing overdue',
                      _Filter.submitted => 'Nothing submitted yet',
                      _Filter.all => 'No assignments this term',
                    },
                    message: 'Assignments from the teachers will show here.',
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

  Widget _card(dynamic item) {
    final title = sStr(item, ['title']) ?? 'Assignment';
    final subject = sStr(item, ['subjectName']);
    final teacher = sStr(item, ['teacherName']);
    final due = sLocal(item, ['dueDate']);
    final sub = item is Map ? item['submission'] : null;
    final score = sNum(sub, ['score']);
    final status = _isSubmitted(item)
        ? (sub is Map && sub['isGraded'] == true ? 'Graded' : 'Submitted')
        : (_isOverdue(item) ? 'Overdue' : 'Pending');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showDetails(item),
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
                    due == null ? 'No due date' : 'Due ${sPrettyDate(due)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const Spacer(),
                  if (score != null)
                    Text(
                      'Score ${score % 1 == 0 ? score.toInt() : score.toStringAsFixed(1)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(dynamic item) {
    final title = sStr(item, ['title']) ?? 'Assignment';
    final description = sStr(item, ['description']);
    final attachment = sStr(item, ['attachmentUrl']);
    final due = sLocal(item, ['dueDate']);
    final sub = item is Map ? item['submission'] : null;
    final submittedAt = sLocal(sub, ['submittedAt']);
    final answer = sStr(sub, ['submissionText']);
    final feedback = sStr(sub, ['feedback']);
    final score = sNum(sub, ['score']);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: .65,
        minChildSize: .4,
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
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  color: StudentColors.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                due == null ? 'No due date' : 'Due ${sPrettyDate(due)}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              if (description != null) ...[
                const SizedBox(height: 16),
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
                const SizedBox(height: 12),
                SelectableText(
                  attachment,
                  style: const TextStyle(
                    color: StudentColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Divider(color: Colors.grey.shade200, height: 1),
              const SizedBox(height: 16),
              if (sub is! Map)
                Row(
                  children: [
                    Icon(
                      Icons.hourglass_empty_rounded,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Not submitted yet',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              else ...[
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (score != null) StatusChip('Score ${score.toStringAsFixed(0)}'),
                  ],
                ),
                if (answer != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: StudentColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(answer, style: const TextStyle(height: 1.5)),
                  ),
                ],
                if (feedback != null) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Teacher feedback',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(feedback, style: const TextStyle(height: 1.5)),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isSubmitted(dynamic a) => a is Map && a['submission'] is Map;

  bool _isOverdue(dynamic a) {
    final due = sLocal(a, ['dueDate']);
    return due != null && due.isBefore(DateTime.now()) && !_isSubmitted(a);
  }

  int _byDue(dynamic a, dynamic b) {
    final da = sLocal(a, ['dueDate']);
    final db = sLocal(b, ['dueDate']);
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  }
}