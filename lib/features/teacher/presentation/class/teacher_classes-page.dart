import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TeacherClassesPage extends ConsumerWidget {
  const TeacherClassesPage({super.key});

  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(teacherSubjectsProvider);
    final classesAsync = ref.watch(teacherClassesProvider);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Classes',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search_rounded, color: textDark),
          ),
        ],
      ),

      body: subjectsAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator(color: primary));
        },

        error: (error, stack) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.red,
                    size: 40,
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Unable to load your classes',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),

                  const SizedBox(height: 15),

                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(teacherSubjectsProvider);
                      ref.invalidate(teacherClassesProvider);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },

        data: (data) {
          final groupedSubjects = _groupSubjects(data);

          return RefreshIndicator(
            color: primary,
            onRefresh: () async {
              ref.invalidate(teacherSubjectsProvider);
              ref.invalidate(teacherClassesProvider);

              await Future.wait([
                ref.read(teacherSubjectsProvider.future),
                ref.read(teacherClassesProvider.future),
              ]);
            },

            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                // ======================================================
                // CLASS TEACHER SECTION
                // ======================================================
                classesAsync.when(
                  loading: () {
                    return _classTeacherLoading();
                  },

                  error: (error, stack) {
                    return _classTeacherError(context, ref);
                  },

                  data: (classData) {
                    final classTeacherClasses = _extractClassTeacherClasses(
                      classData,
                    );

                    if (classTeacherClasses.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Class Teacher',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          'Classes assigned to you as class teacher',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 14),

                        ...classTeacherClasses.map(
                          (classItem) => _classTeacherCard(context, classItem),
                        ),

                        const SizedBox(height: 25),
                      ],
                    );
                  },
                ),

                // ======================================================
                // SUBJECT TEACHING SECTION
                // ======================================================
                const Text(
                  'Subject Teaching',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${groupedSubjects.length} subjects assigned to you',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),

                const SizedBox(height: 18),

                if (groupedSubjects.isEmpty)
                  _emptySubjects()
                else
                  ...groupedSubjects.map(
                    (subject) => _subjectCard(context, subject: subject),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ================================================================
  // EXTRACT CLASS TEACHER CLASSES
  // ================================================================

  List<Map<String, dynamic>> _extractClassTeacherClasses(dynamic data) {
    if (data == null) {
      return [];
    }

    dynamic value = data;

    if (data is Map) {
      value = data['data'] ?? data['classes'] ?? data['teacherClasses'] ?? [];
    }

    if (value is! List) {
      return [];
    }

    final result = <Map<String, dynamic>>[];

    for (final item in value) {
      if (item is! Map) {
        continue;
      }

      final map = Map<String, dynamic>.from(item);

      final classId = map['classId']?.toString() ?? map['id']?.toString() ?? '';

      final className =
          map['className']?.toString() ??
          map['name']?.toString() ??
          'Unknown Class';

      if (classId.isEmpty) {
        continue;
      }

      result.add({'classId': classId, 'className': className});
    }

    return result;
  }

  // ================================================================
  // CLASS TEACHER CARD
  // ================================================================

  Widget _classTeacherCard(
    BuildContext context,
    Map<String, dynamic> classItem,
  ) {
    final classId = classItem['classId']?.toString() ?? '';
    final className = classItem['className']?.toString() ?? 'Class';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.withOpacity(.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            context.push(
              '/teacher/classes/class-teacher-details',
              extra: {
                'classId': classItem['classId'],
                'className': classItem['className'],
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(.09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Colors.green,
                    size: 25,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        className,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Class Teacher',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // CLASS TEACHER LOADING
  // ================================================================

  Widget _classTeacherLoading() {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: primary),
          ),

          SizedBox(width: 12),

          Text(
            'Loading class teacher assignments...',
            style: TextStyle(color: textDark, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CLASS TEACHER ERROR
  // ================================================================

  Widget _classTeacherError(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade300),

          const SizedBox(width: 10),

          const Expanded(
            child: Text(
              'Unable to load your class-teacher assignments.',
              style: TextStyle(color: textDark, fontSize: 11),
            ),
          ),

          IconButton(
            onPressed: () {
              ref.invalidate(teacherClassesProvider);
            },
            icon: const Icon(Icons.refresh_rounded, color: primary),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // EMPTY SUBJECTS
  // ================================================================

  Widget _emptySubjects() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.menu_book_outlined, size: 38, color: Colors.grey.shade300),

          const SizedBox(height: 10),

          Text(
            'No subjects assigned to you',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // GROUP SUBJECTS BY SUBJECT NAME
  // ================================================================

  List<Map<String, dynamic>> _groupSubjects(dynamic data) {
    if (data == null) {
      return [];
    }

    List<dynamic> items;

    if (data is List) {
      items = data;
    } else if (data is Map) {
      final value = data['data'] ?? data['subjects'] ?? [];

      if (value is List) {
        items = value;
      } else {
        return [];
      }
    } else {
      return [];
    }

    final Map<String, Map<String, dynamic>> grouped = {};

    for (final item in items) {
      if (item is! Map) {
        continue;
      }

      final subjectId = item['subjectId']?.toString() ?? '';

      final subjectName = item['subjectName']?.toString() ?? 'Unknown Subject';

      final code = item['code']?.toString() ?? '';

      final classId = item['classId']?.toString() ?? '';

      final className = item['className']?.toString() ?? 'Unknown Class';

      final key = subjectId.isNotEmpty ? subjectId : subjectName;

      if (!grouped.containsKey(key)) {
        grouped[key] = {
          'subjectId': subjectId,
          'subjectName': subjectName,
          'code': code,
          'classes': <Map<String, String>>[],
        };
      }

      final classes = grouped[key]!['classes'] as List<Map<String, String>>;

      final alreadyExists = classes.any(
        (classItem) => classItem['classId'] == classId,
      );

      if (!alreadyExists) {
        classes.add({'classId': classId, 'className': className});
      }
    }

    return grouped.values.toList();
  }

  // ================================================================
  // SUBJECT CARD
  // ================================================================

  Widget _subjectCard(
    BuildContext context, {
    required Map<String, dynamic> subject,
  }) {
    final subjectName = subject['subjectName']?.toString() ?? 'Subject';

    final code = subject['code']?.toString() ?? '';

    final classes =
        (subject['classes'] as List?)?.cast<Map<String, String>>() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // ----------------------------------------------------------
          // SUBJECT HEADER
          // ----------------------------------------------------------
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primary.withOpacity(.09),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.menu_book_rounded, color: primary),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subjectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      code.isNotEmpty
                          ? '$code • ${classes.length} classes'
                          : '${classes.length} classes',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Divider(color: Colors.grey.shade200, height: 1),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Classes',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          ...classes.map(
            (classItem) =>
                _classItem(context, subject: subject, classItem: classItem),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CLASS ITEM
  // ================================================================

  Widget _classItem(
    BuildContext context, {
    required Map<String, dynamic> subject,
    required Map<String, String> classItem,
  }) {
    final classId = classItem['classId'] ?? '';

    final className = classItem['className'] ?? 'Class';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () {
            context.push(
              '/teacher/classes/details',
              extra: {
                'subjectId': subject['subjectId'],
                'subjectName': subject['subjectName'],
                'classId': classId,
                'className': className,
                'isClassTeacher': false,
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.groups_outlined,
                    color: primary,
                    size: 19,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    className,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
