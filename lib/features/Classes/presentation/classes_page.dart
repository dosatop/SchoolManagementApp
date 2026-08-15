import 'package:app/features/Classes/models/class_model.dart';
import 'package:app/features/Classes/presentation/create_class_page.dart';
import 'package:app/features/Classes/provider/classes_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClassesPage extends ConsumerStatefulWidget {
  final String schoolId;
  final String schoolName;

  const ClassesPage({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  ConsumerState<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends ConsumerState<ClassesPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final classesState = ref.watch(classesProvider(widget.schoolId));

    return Scaffold(
      backgroundColor: background,

      // ============================================================
      // APP BAR
      // ============================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 20,

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Classes',
              style: TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              widget.schoolName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(classesProvider(widget.schoolId));
            },
            icon: const Icon(Icons.refresh_rounded, color: textDark),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // ============================================================
      // FAB
      // ============================================================
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,

        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateClassPage(
                schoolId: widget.schoolId,
                schoolName: widget.schoolName,
              ),
            ),
          );

          if (created == true) {
            ref.invalidate(classesProvider(widget.schoolId));
          }
        },

        icon: const Icon(Icons.add_rounded),

        label: const Text(
          'Create Class',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================
      body: classesState.when(
        loading: () {
          return const Center(child: CircularProgressIndicator(color: primary));
        },

        error: (error, stackTrace) {
          return _ClassesErrorState(
            error: error.toString(),
            onRetry: () {
              ref
                  .read(classesProvider(widget.schoolId).notifier)
                  .refreshClasses();
            },
          );
        },

        data: (classes) {
          final filteredClasses = classes.where((schoolClass) {
            final query = _searchQuery.toLowerCase().trim();

            if (query.isEmpty) {
              return true;
            }

            return schoolClass.name.toLowerCase().contains(query) ||
                (schoolClass.description ?? '').toLowerCase().contains(query);
          }).toList();

          return RefreshIndicator(
            color: primary,

            onRefresh: () {
              return ref
                  .read(classesProvider(widget.schoolId).notifier)
                  .refreshClasses();
            },

            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),

              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),

              children: [
                // ======================================================
                // HEADER CARD
                // ======================================================
                _ClassesHeader(
                  schoolName: widget.schoolName,
                  count: classes.length,
                ),

                const SizedBox(height: 25),

                // ======================================================
                // SEARCH
                // ======================================================
                _SearchField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // ======================================================
                // SECTION HEADER
                // ======================================================
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'School Classes',
                            style: TextStyle(
                              color: textDark,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            'Manage classes belonging to this school.',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),

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
                        '${classes.length}',
                        style: const TextStyle(
                          color: primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ======================================================
                // EMPTY STATE
                // ======================================================
                if (classes.isEmpty)
                  const _ClassesEmptyState()
                // ======================================================
                // SEARCH EMPTY
                // ======================================================
                else if (filteredClasses.isEmpty)
                  _NoSearchResults(query: _searchQuery)
                // ======================================================
                // CLASSES
                // ======================================================
                else
                  ...filteredClasses.map(
                    (schoolClass) => _ClassCard(
                      classModel: schoolClass,
                      onTap: () {
                        // TODO:
                        // Navigate to class management/details.
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// HEADER
// ============================================================================

class _ClassesHeader extends StatelessWidget {
  final String schoolName;
  final int count;

  const _ClassesHeader({required this.schoolName, required this.count});

  static const Color primary = Color(0xFF091993);

  @override
  Widget build(BuildContext context) {
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
          // Icon
          Container(
            width: 58,
            height: 58,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.13),
              borderRadius: BorderRadius.circular(17),
            ),

            child: const Icon(
              Icons.class_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(width: 15),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Classes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  schoolName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),

                const SizedBox(height: 7),

                Text(
                  '$count ${count == 1 ? 'class' : 'classes'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Count
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.12),
              shape: BoxShape.circle,
            ),

            alignment: Alignment.center,

            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SEARCH FIELD
// ============================================================================

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,

      decoration: InputDecoration(
        hintText: 'Search classes...',

        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),

        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),

        filled: true,
        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 15,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF091993), width: 1.3),
        ),
      ),
    );
  }
}

// ============================================================================
// CLASS CARD
// ============================================================================

class _ClassCard extends StatelessWidget {
  final ClassModel classModel;
  final VoidCallback onTap;

  const _ClassCard({required this.classModel, required this.onTap});

  static const Color primary = Color(0xFF091993);
  static const Color textDark = Color(0xFF20232E);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 11),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),

          child: Padding(
            padding: const EdgeInsets.all(14),

            child: Row(
              children: [
                // Icon
                Container(
                  width: 50,
                  height: 50,

                  decoration: BoxDecoration(
                    color: const Color(0xFFE9ECFF),
                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: const Icon(
                    Icons.class_outlined,
                    color: primary,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 13),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        classModel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      if (classModel.description != null &&
                          classModel.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 5),

                        Text(
                          classModel.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,

                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 5),

                        Text(
                          'School class',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Arrow
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

// ============================================================================
// EMPTY STATE
// ============================================================================

class _ClassesEmptyState extends StatelessWidget {
  const _ClassesEmptyState();

  static const Color primary = Color(0xFF091993);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 45),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,

            decoration: BoxDecoration(
              color: const Color(0xFFE9ECFF),
              borderRadius: BorderRadius.circular(25),
            ),

            child: const Icon(Icons.class_outlined, size: 40, color: primary),
          ),

          const SizedBox(height: 18),

          const Text(
            'No classes yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF20232E),
            ),
          ),

          const SizedBox(height: 7),

          Text(
            'There are currently no classes created for this school.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          // This can later navigate to CreateClassPage.
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Navigate to CreateClassPage
            },

            icon: const Icon(Icons.add_rounded),

            label: const Text(
              'Create First Class',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),

            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: const BorderSide(color: primary),
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
}

// ============================================================================
// NO SEARCH RESULTS
// ============================================================================

class _NoSearchResults extends StatelessWidget {
  final String query;

  const _NoSearchResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(35),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 45, color: Colors.grey.shade400),

          const SizedBox(height: 14),

          const Text(
            'No classes found',
            style: TextStyle(
              color: Color(0xFF20232E),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'No class matches "$query".',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ERROR STATE
// ============================================================================

class _ClassesErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ClassesErrorState({required this.error, required this.onRetry});

  static const Color primary = Color(0xFF091993);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 75,
              height: 75,

              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(22),
              ),

              child: Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Colors.red.shade600,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Unable to load classes',
              style: TextStyle(
                color: Color(0xFF20232E),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              error,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: onRetry,

              icon: const Icon(Icons.refresh_rounded, size: 18),

              label: const Text('Try Again'),

              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
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
