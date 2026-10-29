import 'package:app/features/parents/models/parent_child_model.dart';
import 'package:app/features/parents/parent_provider.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ParentChildDetailsPage extends ConsumerWidget {
  const ParentChildDetailsPage({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(parentChildProvider(studentId));
    final classAsync = ref.watch(parentChildClassProvider(studentId));
    final subjectsAsync = ref.watch(parentChildSubjectsProvider(studentId));

    final classData = classAsync.valueOrNull;
    final subjects = sList(subjectsAsync.valueOrNull, ['subjects']);

    Future<void> refresh() async {
      ref.invalidate(parentChildProvider(studentId));
      ref.invalidate(parentChildClassProvider(studentId));
      ref.invalidate(parentChildSubjectsProvider(studentId));

      await Future.wait([
        sSafe(ref.read(parentChildProvider(studentId).future)),
        sSafe(ref.read(parentChildClassProvider(studentId).future)),
        sSafe(ref.read(parentChildSubjectsProvider(studentId).future)),
      ]);
    }

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar('Child details'),
      body: RefreshIndicator(
        color: StudentColors.primary,
        onRefresh: refresh,
        child: () {
          if (childAsync.isLoading && !childAsync.hasValue) {
            return const StudentLoadingView(layout: LoadingLayout.detail);
          }

          if (childAsync.hasError && !childAsync.hasValue) {
            return StudentErrorView(
              error: childAsync.error!,
              onRetry: refresh,
              title: 'Unable to load child details',
            );
          }

          final child = childAsync.value!;
          final classTeacher = sStr(classData, ['classTeacherName']);
          final classmates = sNum(classData, ['studentCount']);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              _header(child),

              const SizedBox(height: 24),

              // ---------------- PROGRESS ----------------
              _title('Progress'),
              const SizedBox(height: 10),

              _actionCard(
                icon: Icons.bar_chart_rounded,
                title: 'Results',
                subtitle: 'Test and exam scores this term',
                color: Colors.green,
                onTap: () =>
                    context.push('/parent/child/$studentId/results'),
              ),
              _actionCard(
                icon: Icons.fact_check_rounded,
                title: 'Attendance',
                subtitle: 'Days present, absent and late',
                color: Colors.teal,
                onTap: () =>
                    context.push('/parent/child/$studentId/attendance'),
              ),
              _actionCard(
                icon: Icons.assignment_rounded,
                title: 'Assignments',
                subtitle: 'Homework, deadlines and scores',
                color: Colors.orange,
                onTap: () =>
                    context.push('/parent/child/$studentId/assignments'),
              ),

              // ---------------- CLASS ----------------
              const SizedBox(height: 14),
              _title('Class'),
              const SizedBox(height: 10),

              _infoCard([
                _Info(
                  Icons.class_outlined,
                  'Class',
                  child.className.trim().isEmpty ? null : child.className,
                ),
                _Info(
                  Icons.supervisor_account_outlined,
                  'Class teacher',
                  classTeacher,
                ),
                _Info(
                  Icons.groups_outlined,
                  'Students in class',
                  classmates?.toInt().toString(),
                ),
                _Info(
                  Icons.email_outlined,
                  'Student email',
                  child.email.trim().isEmpty ? null : child.email,
                ),
              ]),

              // ---------------- SUBJECTS ----------------
              if (subjects.isNotEmpty) ...[
                const SizedBox(height: 24),
                _title('Subjects (${subjects.length})'),
                const SizedBox(height: 10),
                Container(
                  decoration: _card(),
                  child: Column(
                    children: [
                      for (var i = 0; i < subjects.length; i++) ...[
                        if (i > 0)
                          Divider(height: 1, color: Colors.grey.shade200),
                        _subjectRow(
                          subjects[i],
                          StudentColors.accents[
                              i % StudentColors.accents.length],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        }(),
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _header(ParentChildModel child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [StudentColors.primary, Color(0xFF2437C5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor: Colors.white,
            child: Text(
              _initials(child.fullName),
              style: const TextStyle(
                color: StudentColors.primary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            child.fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (child.className.trim().isNotEmpty)
                _pill(Icons.class_outlined, child.className),
              if (child.studentNumber.trim().isNotEmpty)
                _pill(Icons.badge_outlined, 'No. ${child.studentNumber}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CARDS
  // ================================================================

  Widget _title(String text) => Text(
    text,
    style: const TextStyle(
      color: StudentColors.textDark,
      fontSize: 17,
      fontWeight: FontWeight.bold,
    ),
  );

  BoxDecoration _card() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Colors.grey.shade200),
  );

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: StudentColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard(List<_Info> items) {
    final visible = items.where((i) => i.value != null).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      decoration: _card(),
      child: Column(
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) Divider(height: 1, color: Colors.grey.shade200),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: StudentColors.primaryLight,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      visible[i].icon,
                      color: StudentColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visible[i].label,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          visible[i].value!,
                          style: const TextStyle(
                            color: StudentColors.textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  Widget _subjectRow(dynamic subject, Color color) {
    final name = sStr(subject, ['subjectName', 'name']) ?? 'Subject';
    final code = sStr(subject, ['code']);
    final teacher = sStr(subject, ['teacherName']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _abbr(code ?? name),
              style: TextStyle(
                color: color,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (teacher != null)
                  Text(
                    teacher,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _abbr(String text) {
    final t = text.trim().toUpperCase();
    return t.length <= 3 ? t : t.substring(0, 3);
  }

  String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

class _Info {
  const _Info(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String? value;
}