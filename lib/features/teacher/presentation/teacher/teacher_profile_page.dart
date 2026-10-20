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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(teacherProfileProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/teacher/dashboard');
            }
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textDark,
            size: 20,
          ),
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: primary),
        ),
        error: (error, stackTrace) => _errorView(ref),
        data: (data) => RefreshIndicator(
          color: primary,
          onRefresh: () async {
            ref.invalidate(teacherProfileProvider);
            await ref.read(teacherProfileProvider.future);
          },
          child: _profileContent(data),
        ),
      ),
      // bottomNavigationBar: _bottomNavigationBar(context),
    );
  }

  // ================================================================
  // PROFILE CONTENT
  // ================================================================

  Widget _profileContent(dynamic data) {
    final teacher = _extractTeacher(data);

    final firstName = _getString(
      teacher,
      ['firstName', 'firstname', 'first_name'],
    );

    final lastName = _getString(
      teacher,
      ['lastName', 'lastname', 'last_name'],
    );

    final fullName = _getString(
          teacher,
          ['fullName', 'full_name', 'name'],
        ) ??
        _buildFullName(firstName, lastName);

    final email = _getString(
      teacher,
      ['email', 'emailAddress', 'email_address'],
    );

    final phone = _getString(
      teacher,
      ['phone', 'phoneNumber', 'phone_number', 'mobile'],
    );

    final gender = _getString(
      teacher,
      ['gender', 'sex'],
    );

    final teacherId = _getString(
      teacher,
      ['id', 'teacherId', 'teacher_id'],
    );

    final qualification = _getString(
      teacher,
      ['qualification', 'qualifications', 'degree'],
    );

    final department = _getString(
      teacher,
      ['department', 'departmentName', 'department_name'],
    );

    final address = _getString(
      teacher,
      ['address', 'homeAddress', 'home_address'],
    );

    final dateOfBirth = _getString(
      teacher,
      ['dateOfBirth', 'date_of_birth', 'dob'],
    );

    final profileImage = _getString(
      teacher,
      [
        'profileImage',
        'profile_image',
        'profilePicture',
        'profile_picture',
        'avatar',
        'image',
        'photo',
      ],
    );

    final displayName =
        (fullName == null || fullName.trim().isEmpty) ? 'Teacher' : fullName;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),
      children: [
        _profileHeader(
          name: displayName,
          email: email,
          profileImage: profileImage,
        ),

        const SizedBox(height: 20),

        _sectionTitle('Personal Information'),

        const SizedBox(height: 10),

        _infoCard(
          children: [
            _infoRow(
              icon: Icons.person_outline_rounded,
              title: 'First Name',
              value: firstName,
            ),
            _divider(),
            _infoRow(
              icon: Icons.person_outline_rounded,
              title: 'Last Name',
              value: lastName,
            ),
            _divider(),
            _infoRow(
              icon: Icons.wc_outlined,
              title: 'Gender',
              value: gender,
            ),
            _divider(),
            _infoRow(
              icon: Icons.cake_outlined,
              title: 'Date of Birth',
              value: dateOfBirth,
            ),
          ],
        ),

        const SizedBox(height: 20),

        _sectionTitle('Contact Information'),

        const SizedBox(height: 10),

        _infoCard(
          children: [
            _infoRow(
              icon: Icons.email_outlined,
              title: 'Email',
              value: email,
            ),
            _divider(),
            _infoRow(
              icon: Icons.phone_outlined,
              title: 'Phone',
              value: phone,
            ),
            _divider(),
            _infoRow(
              icon: Icons.location_on_outlined,
              title: 'Address',
              value: address,
            ),
          ],
        ),

        const SizedBox(height: 20),

        _sectionTitle('Professional Information'),

        const SizedBox(height: 10),

        _infoCard(
          children: [
            _infoRow(
              icon: Icons.badge_outlined,
              title: 'Teacher ID',
              value: teacherId,
            ),
            _divider(),
            _infoRow(
              icon: Icons.school_outlined,
              title: 'Qualification',
              value: qualification,
            ),
            _divider(),
            _infoRow(
              icon: Icons.account_tree_outlined,
              title: 'Department',
              value: department,
            ),
          ],
        ),

        const SizedBox(height: 25),

        _editProfileButton(),
      ],
    );
  }

  // ================================================================
  // PROFILE HEADER
  // ================================================================

  Widget _profileHeader({
    required String name,
    String? email,
    String? profileImage,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            primary,
            Color(0xFF2437C5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _profileAvatar(
            name: name,
            imageUrl: profileImage,
          ),

          const SizedBox(height: 14),

          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (email != null && email.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              email,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(.75),
                fontSize: 11,
              ),
            ),
          ],

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.13),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Teacher',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // PROFILE AVATAR
  // ================================================================

  Widget _profileAvatar({
    required String name,
    String? imageUrl,
  }) {
    final hasImage = imageUrl != null && imageUrl.trim().isNotEmpty;

    return Container(
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.12),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return _avatarFallback(name);
                },
              )
            : _avatarFallback(name),
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: primaryLight,
      child: Center(
        child: Text(
          _getInitials(name),
          style: const TextStyle(
            color: primary,
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SECTION TITLE
  // ================================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: textDark,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ================================================================
  // INFO CARD
  // ================================================================

  Widget _infoCard({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  // ================================================================
  // INFO ROW
  // ================================================================

  Widget _infoRow({
    required IconData icon,
    required String title,
    String? value,
  }) {
    final displayValue =
        value == null || value.trim().isEmpty ? 'Not provided' : value;

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
            child: Icon(
              icon,
              color: primary,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  displayValue,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
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

  Widget _divider() {
    return Divider(
      height: 1,
      thickness: .7,
      color: Colors.grey.shade200,
    );
  }

  // ================================================================
  // EDIT PROFILE BUTTON
  // ================================================================

  Widget _editProfileButton() {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Add your edit-profile route here when ready.
          // context.go('/teacher/profile/edit');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: const Icon(
          Icons.edit_outlined,
          size: 19,
        ),
        label: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ================================================================
  // ERROR VIEW
  // ================================================================

  Widget _errorView(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(.08),
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

            const SizedBox(height: 7),

            Text(
              'Something went wrong while loading your profile.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: () {
                ref.invalidate(teacherProfileProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // EXTRACT TEACHER
  // ================================================================

  Map<String, dynamic> _extractTeacher(dynamic data) {
    if (data is Map) {
      dynamic teacher;

      if (data['teacher'] is Map) {
        teacher = data['teacher'];
      } else if (data['data'] is Map) {
        teacher = data['data'];
      } else {
        teacher = data;
      }

      if (teacher is Map) {
        return Map<String, dynamic>.from(teacher);
      }
    }

    return <String, dynamic>{};
  }

  // ================================================================
  // GET STRING
  // ================================================================

  String? _getString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return null;
  }

  // ================================================================
  // BUILD FULL NAME
  // ================================================================

  String? _buildFullName(
    String? firstName,
    String? lastName,
  ) {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';

    if (first.isEmpty && last.isEmpty) {
      return null;
    }

    if (first.isEmpty) {
      return last;
    }

    if (last.isEmpty) {
      return first;
    }

    return '$first $last';
  }

  // ================================================================
  // INITIALS
  // ================================================================

  String _getInitials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) {
      return 'T';
    }

    if (words.length == 1) {
      return words.first.substring(0, 1).toUpperCase();
    }

    return '${words.first.substring(0, 1)}'
            '${words.last.substring(0, 1)}'
        .toUpperCase();
  }

  // ================================================================
  // BOTTOM NAVIGATION
  // ================================================================

  Widget _bottomNavigationBar(BuildContext context) {
    return NavigationBar(
      backgroundColor: Colors.white,
      elevation: 8,
      selectedIndex: 3,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/teacher/dashboard');
            break;

          case 1:
            context.go('/teacher/classes');
            break;

          case 2:
            context.go('/teacher/assignments');
            break;

          case 3:
            context.go('/teacher/profile');
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded),
          label: 'Classes',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment_rounded),
          label: 'Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
