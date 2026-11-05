import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/presentation/widgets/student_ui.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TeacherProfilePage extends ConsumerWidget {
  const TeacherProfilePage({super.key});

  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(teacherProfileProvider);

    // /teacher/subjects has one row per subject + class the teacher
    // teaches (subjectName + className), which is what the Teaching
    // section shows. /teacher/classes only lists class-teacher classes.
    final classesAsync = ref.watch(teacherSubjectsProvider);

    return Scaffold(
      backgroundColor: background,
      body: RefreshIndicator(
        color: primary,
        onRefresh: () => _refresh(ref),
        child: profileAsync.when(
          skipLoadingOnRefresh: true,
          loading: () => const SafeArea(
            child: StudentLoadingView(layout: LoadingLayout.detail),
          ),
          error: (error, _) => SafeArea(
            child: StudentErrorView(
              error: error,
              onRetry: () => _refresh(ref),
              title: 'Unable to load your profile',
            ),
          ),
          data: (data) => _profileContent(context, ref, data, classesAsync),
        ),
      ),
    );
  }

  // ================================================================
  // REFRESH
  // ================================================================

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(teacherProfileProvider);
    ref.invalidate(teacherSubjectsProvider);

    await Future.wait([
      ref.read(teacherProfileProvider.future).then((_) {}, onError: (_) {}),
      ref.read(teacherSubjectsProvider.future).then((_) {}, onError: (_) {}),
    ]);
  }

  // ================================================================
  // PROFILE CONTENT
  // ================================================================

  Widget _profileContent(
    BuildContext context,
    WidgetRef ref,
    dynamic data,
    AsyncValue<dynamic> classesAsync,
  ) {
    final teacher = _extractTeacher(data);

    final firstName = _str(teacher, ['firstName', 'firstname', 'first_name']);
    final lastName = _str(teacher, [
      'lastName',
      'lastname',
      'last_name',
      'surname',
    ]);

    final fullName =
        _str(teacher, ['fullName', 'full_name', 'name']) ??
        _joinName(firstName, lastName) ??
        'Teacher';

    final email = _str(teacher, ['email', 'emailAddress', 'email_address']);
    final phone = _str(teacher, [
      'phoneNumber',
      'phone',
      'phone_number',
      'mobile',
    ]);
    final address = _str(teacher, ['address', 'homeAddress', 'home_address']);

    final gender = _capitalise(_str(teacher, ['gender', 'sex']));
    final dateOfBirth = _prettyDate(
      _str(teacher, ['dateOfBirth', 'date_of_birth', 'dob']),
    );

    // A human-readable staff number, never the raw database GUID.
    final staffNumber = _str(teacher, [
      'staffNumber',
      'staffId',
      'employeeNumber',
      'employeeId',
      'teacherNumber',
    ]);

    final qualification = _str(teacher, [
      'qualification',
      'qualifications',
      'degree',
    ]);
    final department = _str(teacher, [
      'departmentName',
      'department',
      'department_name',
    ]);
    final schoolName = _str(teacher, ['schoolName', 'school']);

    final profileImage = _str(teacher, [
      'profileImage',
      'profile_image',
      'profilePicture',
      'profile_picture',
      'avatar',
      'image',
      'photo',
    ]);

    final teaching = _teachingList(classesAsync.valueOrNull);

    final classCount = teaching.map((t) => t.className).toSet().length;
    final subjectCount = teaching
        .map((t) => t.subject)
        .whereType<String>()
        .toSet()
        .length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: EdgeInsets.zero,
      children: [
        _profileHeader(
          context: context,
          name: fullName,
          email: email,
          schoolName: schoolName,
          profileImage: profileImage,
          classes: classesAsync.isLoading && !classesAsync.hasValue
              ? null
              : classCount,
          subjects: classesAsync.isLoading && !classesAsync.hasValue
              ? null
              : subjectCount,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

        // ------------------------------------------------------------
        // TEACHING
        // ------------------------------------------------------------
        if (teaching.isNotEmpty) ...[
          const SizedBox(height: 22),
          _sectionTitle('Teaching'),
          const SizedBox(height: 10),
          _teachingCard(teaching),
        ],

        // ------------------------------------------------------------
        // INFO SECTIONS (empty rows and sections are hidden)
        // ------------------------------------------------------------
        ..._section('Contact', [
          _InfoItem(Icons.email_outlined, 'Email', email, copyable: true),
          _InfoItem(Icons.phone_outlined, 'Phone', phone, copyable: true),
          _InfoItem(Icons.location_on_outlined, 'Address', address),
        ]),

        ..._section('Personal', [
          _InfoItem(Icons.person_outline_rounded, 'First name', firstName),
          _InfoItem(Icons.person_outline_rounded, 'Last name', lastName),
          _InfoItem(Icons.wc_outlined, 'Gender', gender),
          _InfoItem(Icons.cake_outlined, 'Date of birth', dateOfBirth),
        ]),

        ..._section('Professional', [
          _InfoItem(Icons.badge_outlined, 'Staff number', staffNumber),
          _InfoItem(Icons.school_outlined, 'Qualification', qualification),
          _InfoItem(Icons.account_tree_outlined, 'Department', department),
        ]),

        const SizedBox(height: 28),

        _logoutButton(context, ref),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a titled info card, skipping empty values.
  /// Returns nothing if every value in the section is empty.
  List<Widget> _section(String title, List<_InfoItem> items) {
    final visible = items.where((i) => i.value != null).toList();

    if (visible.isEmpty) return const [];

    return [
      const SizedBox(height: 22),
      _sectionTitle(title),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            for (var i = 0; i < visible.length; i++) ...[
              if (i > 0)
                Divider(height: 1, thickness: .7, color: Colors.grey.shade200),
              _InfoRowView(item: visible[i]),
            ],
          ],
        ),
      ),
    ];
  }

  // ================================================================
  // HEADER
  // ================================================================

  Widget _profileHeader({
    required BuildContext context,
    required String name,
    String? email,
    String? schoolName,
    String? profileImage,
    int? classes,
    int? subjects,
  }) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, top + 14, 20, 24),
      decoration: const BoxDecoration(
        gradient: kStudentGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const Text(
            'My Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          _avatar(name: name, imageUrl: profileImage),
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
          if (email != null) ...[
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
              _headerPill(Icons.verified_user_outlined, 'Teacher'),
              if (schoolName != null)
                _headerPill(Icons.school_outlined, schoolName),
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
                HeroStat('Classes', '${classes ?? ''}', loading: classes == null),
                Container(
                  width: 1,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white.withValues(alpha: .18),
                ),
                HeroStat(
                  'Subjects',
                  '${subjects ?? ''}',
                  loading: subjects == null,
                ),
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
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar({required String name, String? imageUrl}) {
    final hasImage = imageUrl != null && imageUrl.startsWith('http');

    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .25),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: .14), blurRadius: 14),
        ],
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _avatarFallback(name),
              )
            : _avatarFallback(name),
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: primaryLight,
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: const TextStyle(
          color: primary,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ================================================================
  // TEACHING (subjects + classes)
  // ================================================================

  Widget _teachingCard(List<({String? subject, String className})> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item.subject == null
                        ? item.className
                        : '${item.subject} · ${item.className}',
                    style: const TextStyle(
                      color: primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }


  // ================================================================
  // INFO ROW / SECTION TITLE
  // ================================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: textDark,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }


  // ================================================================
  // LOGOUT
  // ================================================================

  Widget _logoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () => _logout(context, ref),
        icon: const Icon(Icons.logout_rounded, size: 19),
        label: const Text(
          'Log out',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
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

    await ref.read(authProvider.notifier).logout();

    if (!context.mounted) return;

    context.go('/login');
  }

  // ================================================================
  // ERROR
  // ================================================================


  /// Centers [child] inside a scrollable so pull-to-refresh still works
  /// on loading and error states.

  // ================================================================
  // DATA HELPERS
  // ================================================================

  Map<String, dynamic> _extractTeacher(dynamic data) {
    if (data is! Map) return const {};

    for (final key in ['teacher', 'data', 'profile']) {
      final value = data[key];
      if (value is Map) return Map<String, dynamic>.from(value);
    }

    return Map<String, dynamic>.from(data);
  }

  /// First non-empty value for [keys]. Nested objects (e.g. a
  /// department object) resolve to their `name`.
  String? _str(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      var value = data[key];

      if (value is Map) value = value['name'] ?? value['title'];
      if (value == null || value is List) continue;

      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }

    return null;
  }

  List<({String? subject, String className})> _teachingList(dynamic data) {
    List<dynamic> items = const [];

    if (data is List) {
      items = data;
    } else if (data is Map) {
      final list = data['subjects'] ?? data['classes'] ?? data['data'];
      if (list is List) items = list;
    }

    final result = <({String? subject, String className})>[];
    final seen = <String>{};

    for (final item in items) {
      if (item is! Map) continue;

      final map = Map<String, dynamic>.from(item);
      final className = _str(map, ['className', 'class', 'name']);
      if (className == null) continue;

      final subject = _str(map, ['subjectName', 'subject']);

      if (seen.add('$subject|$className')) {
        result.add((subject: subject, className: className));
      }
    }

    return result;
  }

  String? _joinName(String? first, String? last) {
    final name = [first, last].whereType<String>().join(' ').trim();
    return name.isEmpty ? null : name;
  }

  String? _capitalise(String? value) {
    if (value == null || value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// "1994-05-12T00:00:00Z" -> 12 May 1994 (UTC calendar day).
  String? _prettyDate(String? raw) {
    if (raw == null) return null;

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final d = parsed.isUtc ? parsed : parsed.toUtc();
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) return 'T';
    if (words.length == 1) return words.first[0].toUpperCase();

    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

// ==================================================================
// SMALL MODEL
// ==================================================================

class _InfoItem {
  final IconData icon;
  final String label;
  final String? value;
  final bool copyable;

  const _InfoItem(this.icon, this.label, this.value, {this.copyable = false});
}

class _InfoRowView extends StatelessWidget {
  const _InfoRowView({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
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
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('${item.label} copied'),
                    ),
                  );
              },
              icon: Icon(Icons.copy_rounded, size: 18, color: Colors.grey.shade500),
            ),
        ],
      ),
    );
  }
}
