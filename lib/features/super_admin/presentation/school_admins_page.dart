import 'package:app/features/super_admin/presentation/create_school_admin_page.dart';
import 'package:app/features/super_admin/provider/school_admins_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SchoolAdminsPage extends ConsumerWidget {
  final String schoolId;
  final String schoolName;

  const SchoolAdminsPage({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(schoolAdminsProvider(schoolId));

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 20,

        title: const Text(
          'School Administrators',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(schoolAdminsProvider(schoolId));
            },
            icon: const Icon(Icons.refresh_rounded, color: textDark),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: state.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: primary)),

          error: (error, stackTrace) {
            return _errorState(context, ref, error);
          },

          data: (admins) {
            return RefreshIndicator(
              color: primary,
              onRefresh: () async {
                ref.invalidate(schoolAdminsProvider(schoolId));

                await ref.read(schoolAdminsProvider(schoolId).future);
              },

              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),

                children: [
                  // ====================================================
                  // SCHOOL HEADER
                  // ====================================================
                  _schoolHeader(admins.length),

                  const SizedBox(height: 25),

                  // ====================================================
                  // PAGE TITLE
                  // ====================================================
                  const Text(
                    'Administrators',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Manage administrators for $schoolName.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),

                  const SizedBox(height: 15),

                  // ====================================================
                  // ADMIN LIST
                  // ====================================================
                  if (admins.isEmpty)
                    _emptyState(context)
                  else
                    ...List.generate(admins.length, (index) {
                      final admin = admins[index];

                      return _adminCard(context, admin, index);
                    }),
                ],
              ),
            );
          },
        ),
      ),

      // ==============================================================
      // CREATE ADMIN BUTTON
      // ==============================================================
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,

        elevation: 5,

        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateSchoolAdminPage(
                schoolId: schoolId,
                schoolName: schoolName,
              ),
            ),
          );

          ref.invalidate(schoolAdminsProvider(schoolId));
        },

        icon: const Icon(Icons.person_add_alt_1_rounded),

        label: const Text(
          'Add Administrator',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ================================================================
  // SCHOOL HEADER
  // ================================================================

  Widget _schoolHeader(int adminCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, Color(0xFF2638C4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(23),

        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.13),
              borderRadius: BorderRadius.circular(17),
            ),

            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.white,
              size: 31,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schoolName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'School administrators',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              borderRadius: BorderRadius.circular(15),
            ),

            child: Column(
              children: [
                Text(
                  '$adminCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Text(
                  'Admins',
                  style: TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ADMIN CARD
  // ================================================================

  Widget _adminCard(BuildContext context, dynamic admin, int index) {
    final fullName = admin.fullName ?? '';
    final email = admin.email ?? '';
    final phone = admin.phoneNumber ?? '';

    final initial = fullName.trim().isNotEmpty
        ? fullName.trim()[0].toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          borderRadius: BorderRadius.circular(18),

          onTap: () {
            // Admin details can be opened here later.
          },

          child: Padding(
            padding: const EdgeInsets.all(15),

            child: Row(
              children: [
                // ====================================================
                // AVATAR
                // ====================================================
                Container(
                  width: 52,
                  height: 52,

                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: primary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 13),

                // ====================================================
                // DETAILS
                // ====================================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        fullName.isEmpty ? 'Unnamed Administrator' : fullName,

                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 5),

                        Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),

                            const SizedBox(width: 5),

                            Expanded(
                              child: Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,

                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),

                            const SizedBox(width: 5),

                            Text(
                              phone,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ====================================================
                // ROLE BADGE
                // ====================================================
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(.09),
                    borderRadius: BorderRadius.circular(10),
                  ),

                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // EMPTY STATE
  // ================================================================

  Widget _emptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 40),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,

            decoration: BoxDecoration(
              color: primaryLight,
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: primary,
              size: 34,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'No administrators yet',
            style: TextStyle(
              color: textDark,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'Create the first administrator for $schoolName.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateSchoolAdminPage(
                    schoolId: schoolId,
                    schoolName: schoolName,
                  ),
                ),
              );
            },

            icon: const Icon(Icons.person_add_alt_1, size: 18),

            label: const Text('Create Administrator'),

            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 0,

              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // ERROR STATE
  // ================================================================

  Widget _errorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 70,
              height: 70,

              decoration: BoxDecoration(
                color: Colors.red.withOpacity(.08),
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 35,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Unable to load administrators',
              textAlign: TextAlign.center,

              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error.toString(),
              textAlign: TextAlign.center,

              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(schoolAdminsProvider(schoolId));
              },

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('Try Again'),

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
        ),
      ),
    );
  }
}
