import 'package:app/features/auth/provider/auth_provider.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
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

      // This page is a tab in the teacher dashboard, so there is no
      // back button. Logout lives in the app bar.
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 20,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context, ref),
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: RefreshIndicator(
        color: primary,
        onRefresh: () => _refresh(ref),
        child: profileAsync.when(
          skipLoadingOnRefresh: true,
          loading: () => _scrollable(
            context,
            const CircularProgressIndicator(color: primary),
          ),
          error: (error, _) => _scrollable(context, _errorView(ref)),
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

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        _profileHeader(
          name: fullName,
          email: email,
          schoolName: schoolName,
          profileImage: profileImage,
        ),

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
          _InfoItem(Icons.email_outlined, 'Email', email),
          _InfoItem(Icons.phone_outlined, 'Phone', phone),
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
              _infoRow(visible[i]),
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
    required String name,
    String? email,
    String? schoolName,
    String? profileImage,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, Color(0xFF2437C5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: .22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
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
              fontWeight: FontWeight.bold,
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
                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(height: 14),

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
      width: 92,
      height: 92,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
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
    final classCount = items.map((i) => i.className).toSet().length;
    final subjectCount = items
        .map((i) => i.subject)
        .whereType<String>()
        .toSet()
        .length;

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
          Row(
            children: [
              _miniStat(Icons.class_outlined, '$classCount', 'Classes'),
              const SizedBox(width: 10),
              _miniStat(Icons.menu_book_outlined, '$subjectCount', 'Subjects'),
            ],
          ),

          const SizedBox(height: 14),

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

  Widget _miniStat(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Icon(icon, color: primary, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
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

  Widget _infoRow(_InfoItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primaryLight,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, color: primary, size: 20),
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
                    color: textDark,
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

  // ================================================================
  // LOGOUT
  // ================================================================

  Widget _logoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _logout(context, ref),
        icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 19),
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
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
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

    await ref.read(authProvider.notifier).logout();

    if (!context.mounted) return;

    context.go('/login');
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _errorView(WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: .08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_off_outlined,
            color: Colors.red,
            size: 30,
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'Unable to load profile',
          style: TextStyle(
            color: textDark,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pull down or tap retry to try again.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _refresh(ref),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  /// Centers [child] inside a scrollable so pull-to-refresh still works
  /// on loading and error states.
  Widget _scrollable(BuildContext context, Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * .65,
          child: Center(
            child: Padding(padding: const EdgeInsets.all(24), child: child),
          ),
        ),
      ],
    );
  }

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

  const _InfoItem(this.icon, this.label, this.value);
}
