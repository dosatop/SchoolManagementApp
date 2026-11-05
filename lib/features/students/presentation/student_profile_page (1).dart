import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/presentation/widgets/student_ui.dart';
import 'package:app/features/students/provider/students_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ==================================================================
// STUDENT PROFILE PAGE
// ==================================================================
//   GET /student/profile   -> name, roll number, class, school
//   GET /student/class     -> class details + class teacher
//   GET /student/subjects  -> subject list
//
// Works as a bottom-navigation tab and as a pushed page.

class StudentProfilePage extends ConsumerWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(studentProfileProvider);
    final classAsync = ref.watch(studentClassProvider);
    final subjectsAsync = ref.watch(studentSubjectsProvider);

    final student = profileAsync.valueOrNull;
    final classData = _classMap(classAsync.valueOrNull);
    final subjects = sList(subjectsAsync.valueOrNull, ['subjects']);

    Future<void> refresh() async {
      ref.invalidate(studentClassProvider);
      ref.invalidate(studentSubjectsProvider);

      await Future.wait([
        sSafe(ref.read(studentProfileProvider.notifier).refresh()),
        sSafe(ref.read(studentClassProvider.future)),
        sSafe(ref.read(studentSubjectsProvider.future)),
      ]);
    }

    return Scaffold(
      backgroundColor: StudentColors.background,
      body: RefreshIndicator(
        color: StudentColors.primary,
        onRefresh: refresh,
        child: () {
          if (profileAsync.isLoading && student == null) {
            return const SafeArea(
              child: StudentLoadingView(layout: LoadingLayout.detail),
            );
          }

          if (profileAsync.hasError && student == null) {
            return SafeArea(
              child: StudentErrorView(
                error: profileAsync.error!,
                onRetry: refresh,
                title: 'Unable to load your profile',
              ),
            );
          }

          if (student == null) {
            return const SafeArea(
              child: StudentEmptyView(
                icon: Icons.person_off_outlined,
                title: 'Profile not found',
                message: 'Please contact your school admin.',
              ),
            );
          }

          final className =
              sStr(classData, ['className', 'name']) ?? _clean(student.className);
          final classLevel = sStr(classData, ['levelName', 'level', 'classLevel']);
          final classArm = sStr(classData, ['arm', 'armName', 'section']);
          final classTeacher = sStr(classData, [
            'classTeacherName',
            'classTeacher',
            'teacherName',
          ]);
          final classmates = sNum(classData, [
            'studentCount',
            'studentsCount',
            'totalStudents',
          ]);
          final schoolName =
              _clean(student.schoolName) ?? sStr(classData, ['schoolName']);
          final rollNumber = _clean(student.studentNumber);

          final canPop = Navigator.of(context).canPop();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.zero,
            children: [
              // ---------------- HEADER ----------------
              _header(
                context: context,
                canPop: canPop,
                name: student.fullName,
                rollNumber: rollNumber,
                className: className,
                schoolName: schoolName,
                subjects: subjectsAsync.isLoading && !subjectsAsync.hasValue
                    ? '…'
                    : subjectsAsync.hasError && !subjectsAsync.hasValue
                    ? '—'
                    : '${subjects.length}',
                classmates: classAsync.isLoading && !classAsync.hasValue
                    ? '…'
                    : classmates == null
                    ? '—'
                    : '${classmates.toInt()}',
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---------------- STUDENT ----------------
                    ..._section('Student details', [
                      _Info(
                        Icons.person_outline_rounded,
                        'Full name',
                        student.fullName,
                      ),
                      _Info(
                        Icons.badge_outlined,
                        'Roll number',
                        rollNumber,
                        copyable: true,
                      ),
                      _Info(Icons.school_outlined, 'School', schoolName),
                    ], context),

                    // ---------------- CLASS ----------------
                    ..._section('My class', [
                      _Info(Icons.class_outlined, 'Class', className),
                      _Info(Icons.stairs_outlined, 'Level', classLevel),
                      _Info(Icons.segment_rounded, 'Arm', classArm),
                      _Info(
                        Icons.supervisor_account_outlined,
                        'Class teacher',
                        classTeacher,
                      ),
                    ], context),

                    // ---------------- SUBJECTS ----------------
                    if (subjects.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      SectionHeader(
                        'My subjects',
                        subtitle: '${subjects.length} this term',
                      ),
                      const SizedBox(height: 10),
                      SoftCard(
                        padding: const EdgeInsets.all(14),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < subjects.length; i++)
                              _subjectChip(
                                sStr(subjects[i], ['subjectName', 'name']) ??
                                    'Subject',
                                StudentColors.accents[
                                    i % StudentColors.accents.length],
                              ),
                          ],
                        ),
                      ),
                    ],

                    // ---------------- ACCOUNT ----------------
                    const SizedBox(height: 22),
                    const SectionHeader('Account'),
                    const SizedBox(height: 10),
                    SoftCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          _actionRow(
                            icon: Icons.fact_check_outlined,
                            label: 'My attendance',
                            color: const Color(0xFF0D9488),
                            onTap: () => context.push('/student/attendance'),
                          ),
                          Divider(height: 1, color: Colors.grey.shade100),
                          _actionRow(
                            icon: Icons.calendar_month_outlined,
                            label: 'Timetable',
                            color: const Color(0xFF7C3AED),
                            onTap: () => context.push('/student/timetable'),
                          ),
                          Divider(height: 1, color: Colors.grey.shade100),
                          _actionRow(
                            icon: Icons.help_outline_rounded,
                            label: 'Wrong details? Contact your school admin',
                            color: Colors.blueGrey,
                            onTap: null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ---------------- LOGOUT ----------------
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmLogout(context, ref),
                        icon: const Icon(Icons.logout_rounded, size: 19),
                        label: const Text(
                          'Log out',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade700,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }(),
      ),
    );
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _header({
    required BuildContext context,
    required bool canPop,
    required String name,
    String? rollNumber,
    String? className,
    String? schoolName,
    required String subjects,
    required String classmates,
  }) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 10, 20, 24),
      decoration: const BoxDecoration(
        gradient: kStudentGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (canPop)
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                )
              else
                const SizedBox(width: 48),
              const Expanded(
                child: Text(
                  'My Profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: 96,
            height: 96,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .2),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .15),
                    blurRadius: 16,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                studentInitials(name, fallback: 'S'),
                style: const TextStyle(
                  color: StudentColors.primary,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (schoolName != null) ...[
            const SizedBox(height: 4),
            Text(
              schoolName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .75),
                fontSize: 12.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _headerPill(Icons.verified_user_outlined, 'Student'),
              if (className != null)
                _headerPill(Icons.class_outlined, className),
              if (rollNumber != null)
                _headerPill(Icons.badge_outlined, 'No. $rollNumber'),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                HeroStat('Subjects', subjects, loading: subjects == '…'),
                Container(
                  width: 1,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white.withValues(alpha: .18),
                ),
                HeroStat('Classmates', classmates, loading: classmates == '…'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerPill(IconData icon, String label) {
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
          Flexible(
            child: Text(
              label,
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
  // SECTIONS
  // ================================================================

  /// Empty values are skipped; the section hides if nothing is left.
  List<Widget> _section(String title, List<_Info> items, BuildContext context) {
    final visible = items.where((i) => i.value != null).toList();
    if (visible.isEmpty) return const [];

    return [
      const SizedBox(height: 22),
      SectionHeader(title),
      const SizedBox(height: 10),
      SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Column(
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0) Divider(height: 1, color: Colors.grey.shade100),
              _infoRow(visible[i], context),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _infoRow(_Info item, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          IconBadge(item.icon, color: StudentColors.primary, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  item.value!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: StudentColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (item.copyable)
            IconButton(
              tooltip: 'Copy',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: item.value!));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('${item.label} copied'),
                  ),
                );
              },
              icon: Icon(
                Icons.copy_rounded,
                size: 18,
                color: Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            IconBadge(icon, color: color, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: onTap == null
                      ? Colors.grey.shade600
                      : StudentColors.textDark,
                  fontSize: onTap == null ? 12.5 : 14,
                  fontWeight: onTap == null ? FontWeight.w500 : FontWeight.w700,
                ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _subjectChip(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // LOGOUT
  // ================================================================

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(Icons.logout_rounded, color: Colors.red.shade600),
        title: const Text('Log out?'),
        content: const Text(
          'You\'ll need your email and password to sign in again.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(authProvider.notifier).logout();
    } catch (_) {
      // A failing logout endpoint must not block going to login.
    }

    if (context.mounted) context.go('/login');
  }

  // ================================================================
  // HELPERS
  // ================================================================

  /// /student/class may return the class directly or wrapped.
  Map? _classMap(dynamic data) {
    if (data is! Map) return null;

    for (final key in ['class', 'data']) {
      final value = data[key];
      if (value is Map) return value;
    }

    return data;
  }

  String? _clean(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }
}

class _Info {
  const _Info(this.icon, this.label, this.value, {this.copyable = false});

  final IconData icon;
  final String label;
  final String? value;
  final bool copyable;
}
