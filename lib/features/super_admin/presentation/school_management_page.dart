import 'package:app/features/super_admin/models/school_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SchoolManagementPage extends StatelessWidget {
  final SchoolModel school;

  const SchoolManagementPage({super.key, required this.school});

  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // ============================================================
      // APP BAR
      // ============================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        titleSpacing: 0,

        title: const Text(
          'School Management',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded, color: textDark),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),

          children: [
            // ========================================================
            // SCHOOL HERO
            // ========================================================
            _schoolHero(),

            const SizedBox(height: 22),

            // ========================================================
            // SCHOOL STATISTICS
            // ========================================================
            const Text(
              'School Overview',
              style: TextStyle(
                color: textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'A quick overview of this school.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            const SizedBox(height: 13),

            _overviewStats(),

            const SizedBox(height: 28),

            // ========================================================
            // SCHOOL INFORMATION
            // ========================================================
            const Text(
              'School Information',
              style: TextStyle(
                color: textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Basic information about the school.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            const SizedBox(height: 13),

            _schoolInformation(),

            const SizedBox(height: 28),

            // ========================================================
            // MANAGEMENT
            // ========================================================
            const Text(
              'Management',
              style: TextStyle(
                color: textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Manage users, academics and school administration.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            const SizedBox(height: 14),

            // ========================================================
            // ADMIN
            // ========================================================
            _managementTile(
              icon: Icons.admin_panel_settings_outlined,
              title: 'School Administrators',
              subtitle: 'Create and manage school administrators',
              color: Colors.orange,
              onTap: () {
                context.push(
                  '/schools/${school.id}/admins',
                  extra: school.name,
                );
              },
            ),

            // ========================================================
            // TEACHERS
            // ========================================================
            _managementTile(
              icon: Icons.people_outline,
              title: 'Teachers',
              subtitle: 'Manage teachers in this school',
              color: Colors.green,
              onTap: () {
                // Coming next
              },
            ),

            // ========================================================
            // STUDENTS
            // ========================================================
            _managementTile(
              icon: Icons.groups_outlined,
              title: 'Students',
              subtitle: 'Manage students in this school',
              color: Colors.purple,
              onTap: () {
                // Coming next
              },
            ),

            // ========================================================
            // CLASSES
            // ========================================================
            _managementTile(
              icon: Icons.class_outlined,
              title: 'Classes',
              subtitle: 'Create and manage school classes',
              color: Colors.blue,
              onTap: () {
                // Coming next
              },
            ),

            // ========================================================
            // SUBJECTS
            // ========================================================
            _managementTile(
              icon: Icons.menu_book_outlined,
              title: 'Subjects',
              subtitle: 'Manage subjects offered by the school',
              color: Colors.teal,
              onTap: () {
                // Coming next
              },
            ),

            const SizedBox(height: 15),

            // ========================================================
            // PRIMARY ACTION
            // ========================================================
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push(
                    '/schools/${school.id}/admins',
                    extra: school.name,
                  );
                },

                icon: const Icon(Icons.person_add_alt_1_rounded),

                label: const Text(
                  'Create School Admin',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // SCHOOL HERO
  // ================================================================

  Widget _schoolHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, Color(0xFF2638C4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================================================
          // ICON + STATUS
          // ==========================================================
          Row(
            children: [
              Container(
                width: 58,
                height: 58,

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.14),
                  borderRadius: BorderRadius.circular(17),
                ),

                child: const Icon(
                  Icons.school_outlined,
                  color: Colors.white,
                  size: 31,
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),

                child: const Row(
                  children: [
                    Icon(Icons.circle, color: Colors.greenAccent, size: 8),

                    SizedBox(width: 6),

                    Text(
                      'Active',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ==========================================================
          // SCHOOL NAME
          // ==========================================================
          Text(
            school.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,

            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // ==========================================================
          // ADDRESS
          // ==========================================================
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.white70,
                size: 16,
              ),

              const SizedBox(width: 5),

              Expanded(
                child: Text(
                  school.address,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
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
  // OVERVIEW STATS
  // ================================================================

  Widget _overviewStats() {
    final usersCount = school.users.length;
    final classesCount = school.classes.length;
    final subjectsCount = school.subjects.length;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.people_outline,
            value: usersCount,
            title: 'Users',
            color: primary,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _statCard(
            icon: Icons.class_outlined,
            value: classesCount,
            title: 'Classes',
            color: Colors.green,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _statCard(
            icon: Icons.menu_book_outlined,
            value: subjectsCount,
            title: 'Subjects',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  // ================================================================
  // STAT CARD
  // ================================================================

  Widget _statCard({
    required IconData icon,
    required int value,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(11),
            ),

            child: Icon(icon, color: color, size: 21),
          ),

          const SizedBox(height: 12),

          Text(
            '$value',
            style: const TextStyle(
              color: textDark,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // SCHOOL INFORMATION
  // ================================================================

  Widget _schoolInformation() {
    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        children: [
          _infoRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: school.address,
          ),

          if (school.email != null && school.email!.isNotEmpty)
            _infoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: school.email!,
            ),

          if (school.phoneNumber != null && school.phoneNumber!.isNotEmpty)
            _infoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: school.phoneNumber!,
            ),
        ],
      ),
    );
  }

  // ================================================================
  // INFO ROW
  // ================================================================

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            width: 38,
            height: 38,

            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F8),
              borderRadius: BorderRadius.circular(11),
            ),

            child: Icon(icon, color: Colors.grey.shade700, size: 19),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
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

  // ================================================================
  // MANAGEMENT TILE
  // ================================================================

  Widget _managementTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),

          child: Padding(
            padding: const EdgeInsets.all(14),

            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,

                  decoration: BoxDecoration(
                    color: color.withOpacity(.09),
                    borderRadius: BorderRadius.circular(13),
                  ),

                  child: Icon(icon, color: color, size: 23),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,

                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Container(
                  width: 32,
                  height: 32,

                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
