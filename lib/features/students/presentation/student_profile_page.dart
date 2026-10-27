import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/provider/students_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ==================================================================
// STUDENT PROFILE PAGE
// ==================================================================
// Data:
//   GET /student/profile   -> name, roll number, class, school
//   GET /student/class     -> class details + class teacher
//   GET /student/subjects  -> subject count + list
//
// Works as a bottom-navigation tab (no back arrow) and as a pushed
// page (back arrow appears automatically).

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
      appBar: studentAppBar(
        'My Profile',
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: StudentColors.primary,
        onRefresh: refresh,
        child: () {
          if (profileAsync.isLoading && student == null) {
            return const StudentLoadingView();
          }

          if (profileAsync.hasError && student == null) {
            return StudentErrorView(
              error: profileAsync.error!,
              onRetry: refresh,
              title: 'Unable to load your profile',
            );
          }

          if (student == null) {
            return const StudentEmptyView(
              icon: Icons.person_off_outlined,
              title: 'Profile not found',
              message: 'Please contact your school admin.',
            );
          }

          // ------------------------------------------------------
          // VALUES
          // ------------------------------------------------------
          final className =
              sStr(classData, ['className', 'name']) ?? _clean(student.className);
          final classLevel = sStr(classData, ['level', 'classLevel']);
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

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              // ---------------- HEADER ----------------
              _header(
                name: student.fullName,
                rollNumber: rollNumber,
                className: className,
              ),

              const SizedBox(height: 16),

              // ---------------- QUICK STATS ----------------
              Row(
                children: [
                  Expanded(
                    child: _miniStat(
                      icon: Icons.menu_book_rounded,
                      label: 'Subjects',
                      value: subjectsAsync.isLoading && !subjectsAsync.hasValue
                          ? '…'
                          : subjectsAsync.hasError && !subjectsAsync.hasValue
                          ? '—'
                          : '${subjects.length}',
                      color: StudentColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _miniStat(
                      icon: Icons.groups_rounded,
                      label: 'Classmates',
                      value: classAsync.isLoading && !classAsync.hasValue
                          ? '…'
                          : classmates == null
                          ? '—'
                          : '${classmates.toInt()}',
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),

              // ---------------- STUDENT DETAILS ----------------
              ..._section('Student details', [
                _Info(Icons.person_outline_rounded, 'Full name', student.fullName),
                _Info(Icons.badge_outlined, 'Roll number', rollNumber),
                _Info(Icons.school_outlined, 'School', schoolName),
              ]),

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
              ]),

              // ---------------- SUBJECTS ----------------
              if (subjects.isNotEmpty) ...[
                const SizedBox(height: 22),
                _sectionTitle('My subjects'),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: _cardDecoration(),
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

              const SizedBox(height: 28),

              // ---------------- LOGOUT ----------------
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context, ref),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 19,
                  ),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
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
    required String name,
    String? rollNumber,
    String? className,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [StudentColors.primary, Color(0xFF2437C5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: StudentColors.primary.withValues(alpha: .22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .14),
                  blurRadius: 14,
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundColor: StudentColors.primaryLight,
              child: Text(
                _initials(name),
                style: const TextStyle(
                  color: StudentColors.primary,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
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
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _headerPill(Icons.verified_user_outlined, 'Student'),
              if (className != null) _headerPill(Icons.class_outlined, className),
              if (rollNumber != null)
                _headerPill(Icons.badge_outlined, 'No. $rollNumber'),
            ],
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
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // MINI STAT
  // ================================================================

  Widget _miniStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: StudentColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SECTIONS
  // ================================================================

  /// Titled card of rows. Empty values are skipped, and the whole
  /// section is hidden if nothing is left.
  List<Widget> _section(String title, List<_Info> items) {
    final visible = items.where((i) => i.value != null).toList();
    if (visible.isEmpty) return const [];

    return [
      const SizedBox(height: 22),
      _sectionTitle(title),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0)
                Divider(height: 1, thickness: .7, color: Colors.grey.shade200),
              _infoRow(visible[i]),
            ],
          ],
        ),
      ),
    ];
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: StudentColors.textDark,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _infoRow(_Info item) {
    return Padding(
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
            child: Icon(item.icon, color: StudentColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
                const SizedBox(height: 3),
                Text(
                  item.value!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _subjectChip(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Colors.grey.shade200),
  );

  // ================================================================
  // LOGOUT
  // ================================================================

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
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

    if (!context.mounted) return;

    context.go('/login');
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

  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) return 'S';
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
