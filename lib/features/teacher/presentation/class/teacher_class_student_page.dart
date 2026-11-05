import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/presentation/widgets/student_ui.dart';
import 'package:app/features/teacher/presentation/student/teacher_student_details_page.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==================================================================
// TEACHER: STUDENTS IN ONE CLASS (opened from a subject class page)
// ==================================================================

class TeacherClassStudentsPage extends ConsumerStatefulWidget {
  const TeacherClassStudentsPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.classId,
    required this.className,
  });

  final String subjectId;
  final String subjectName;
  final String classId;
  final String className;

  @override
  ConsumerState<TeacherClassStudentsPage> createState() =>
      _TeacherClassStudentsPageState();
}

class _TeacherClassStudentsPageState
    extends ConsumerState<TeacherClassStudentsPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(teacherStudentsProvider(widget.classId));
    await sSafe(ref.read(teacherStudentsProvider(widget.classId).future));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(teacherStudentsProvider(widget.classId));
    final all = [...sList(async.valueOrNull, ['students', 'data'])]
      ..sort(
        (a, b) => (_name(a)).toLowerCase().compareTo(_name(b).toLowerCase()),
      );

    final q = _query.toLowerCase();
    final visible = q.isEmpty
        ? all
        : all.where((s) {
            final text = [
              _name(s),
              sStr(s, ['studentNumber', 'admissionNumber']),
              sStr(s, ['email']),
            ].whereType<String>().join(' ').toLowerCase();
            return text.contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar(
        'Students',
        subtitle: '${widget.subjectName} · ${widget.className}',
        actions: [
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
        child: () {
          if (async.isLoading && !async.hasValue) {
            return const StudentLoadingView();
          }

          if (async.hasError && !async.hasValue) {
            return StudentErrorView(
              error: async.error!,
              onRetry: _refresh,
              title: 'Unable to load students',
            );
          }

          if (all.isEmpty) {
            return StudentEmptyView(
              icon: Icons.groups_outlined,
              title: 'No students yet',
              message: 'Students added to ${widget.className} will show here.',
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
            children: [
              _summary(all.length),
              const SizedBox(height: 14),
              StudentSearchField(
                controller: _search,
                hint: 'Search name, number or email',
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
                        'No student matches "$_query"',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else
                for (var i = 0; i < visible.length; i++) ...[
                  _card(visible[i], all.indexOf(visible[i])),
                  const SizedBox(height: 10),
                ],
            ],
          );
        }(),
      ),
    );
  }

  Widget _summary(int count) {
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
            child: const Icon(Icons.groups_rounded, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count student${count == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap a student to see results, attendance and tasks',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .75),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(dynamic s, int index) {
    final name = _name(s);
    final number = sStr(s, ['studentNumber', 'admissionNumber']);
    final email = sStr(s, ['email']);
    final phone = sStr(s, ['phoneNumber', 'phone']);
    final color = StudentColors.accents[index % StudentColors.accents.length];

    return SoftCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              TeacherStudentDetailsPage(student: s, isClassTeacher: false),
        ),
      ),
      padding: const EdgeInsets.all(13),
      child: Row(
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
              studentInitials(name, fallback: '?'),
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
                    color: StudentColors.textDark,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (number != null) 'No. $number',
                    if (email != null) email,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          if (phone != null)
            IconButton(
              tooltip: 'Copy phone',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: phone));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('$phone copied'),
                    ),
                  );
              },
              icon: Icon(
                Icons.phone_outlined,
                size: 19,
                color: Colors.grey.shade500,
              ),
            ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  String _name(dynamic s) =>
      sStr(s, ['studentName', 'fullName', 'name']) ?? 'Unknown student';
}
