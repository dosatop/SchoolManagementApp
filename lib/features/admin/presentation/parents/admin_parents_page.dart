import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminParentsPage extends ConsumerWidget {
  final String schoolId;

  const AdminParentsPage({
    super.key,
    required this.schoolId,
  });

  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        title: const Text(
          'Parents',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              ref
                  .read(adminDashboardProvider.notifier)
                  .refresh();
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: textDark,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: dashboardState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: primary,
          ),
        ),

        error: (error, stackTrace) => _errorView(
          context,
          ref,
        ),

        data: (dashboard) {
          final parents = dashboard.parents;

          if (parents.isEmpty) {
            return _emptyView();
          }

          return RefreshIndicator(
            color: primary,

            onRefresh: () {
              return ref
                  .read(adminDashboardProvider.notifier)
                  .refresh();
            },

            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),

              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                35,
              ),

              itemCount: parents.length,

              itemBuilder: (context, index) {
                final parent = parents[index];

                return _parentCard(
                  context: context,
                  parent: parent,
                  schoolId: schoolId,
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // PARENT CARD
  // ================================================================

  Widget _parentCard({
    required BuildContext context,
    required dynamic parent,
    required String schoolId,
  }) {
    final parentName = _getString(
      parent.fullName,
      fallback: 'Parent',
    );

    final email = _getString(
      parent.email,
      fallback: 'No email provided',
    );

    final phone = _getString(
      parent.phoneNumber,
      fallback: 'No phone number',
    );

    final parentId = parent.parentId.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          borderRadius: BorderRadius.circular(18),

          onTap: () {
            context.push(
              '/admin/$schoolId/parents/$parentId',
            );
          },

          child: Padding(
            padding: const EdgeInsets.all(16),

            child: Row(
              children: [
                // ==================================================
                // AVATAR
                // ==================================================

                Container(
                  width: 52,
                  height: 52,

                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: primary,
                    size: 27,
                  ),
                ),

                const SizedBox(width: 14),

                // ==================================================
                // DETAILS
                // ==================================================

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      Text(
                        parentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: Colors.grey,
                          ),

                          const SizedBox(width: 5),

                          Expanded(
                            child: Text(
                              email,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,

                              style: TextStyle(
                                color:
                                    Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: Colors.grey,
                          ),

                          const SizedBox(width: 5),

                          Expanded(
                            child: Text(
                              phone,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,

                              style: TextStyle(
                                color:
                                    Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ==================================================
                // ARROW
                // ==================================================

                Container(
                  width: 32,
                  height: 32,

                  decoration: BoxDecoration(
                    color: primaryLight,
                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: primary,
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

  // ================================================================
  // EMPTY
  // ================================================================

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              width: 75,
              height: 75,

              decoration: BoxDecoration(
                color: primaryLight,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.people_outline_rounded,
                color: primary,
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No Parents Found',
              style: TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              'There are currently no parents registered for this school.',
              textAlign: TextAlign.center,

              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _errorView(
    BuildContext context,
    WidgetRef ref,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 50,
            ),

            const SizedBox(height: 15),

            const Text(
              'Unable to load parents',
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () {
                ref
                    .read(adminDashboardProvider.notifier)
                    .refresh();
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),

              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // SAFE STRING
  // ================================================================

  String _getString(
    dynamic value, {
    required String fallback,
  }) {
    if (value == null) {
      return fallback;
    }

    final result = value.toString().trim();

    if (result.isEmpty) {
      return fallback;
    }

    return result;
  }
}