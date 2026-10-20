import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TeacherStudentsPage extends ConsumerStatefulWidget {
  const TeacherStudentsPage({super.key});

  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  ConsumerState<TeacherStudentsPage> createState() =>
      _TeacherStudentsPageState();
}

class _TeacherStudentsPageState extends ConsumerState<TeacherStudentsPage> {
  String? selectedClassId;

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(teacherStudentsProvider(selectedClassId));

    return Scaffold(
      backgroundColor: TeacherStudentsPage.background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        title: const Text(
          'Students',
          style: TextStyle(
            color: TeacherStudentsPage.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              ref.invalidate(teacherStudentsProvider(selectedClassId));
            },
            icon: const Icon(
              Icons.refresh_rounded,
              color: TeacherStudentsPage.textDark,
            ),
          ),
        ],
      ),

      body: studentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: TeacherStudentsPage.primary),
        ),

        error: (error, stackTrace) {
          return _errorState(error);
        },

        data: (students) {
          return RefreshIndicator(
            color: TeacherStudentsPage.primary,

            onRefresh: () async {
              ref.invalidate(teacherStudentsProvider(selectedClassId));

              await ref.read(teacherStudentsProvider(selectedClassId).future);
            },

            child: _studentsContent(students),
          );
        },
      ),

      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: 0,

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Classes',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],

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
      ),
    );
  }

  // ================================================================
  // STUDENTS CONTENT
  // ================================================================

  Widget _studentsContent(dynamic data) {
    final students = _extractStudents(data);

    if (students.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 100),

          Icon(
            Icons.people_outline_rounded,
            size: 70,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 16),

          const Center(
            child: Text(
              'No students found',
              style: TextStyle(
                color: TeacherStudentsPage.textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Center(
            child: Text(
              'You currently have no students assigned to you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),

      children: [
        const Text(
          'My Students',
          style: TextStyle(
            color: TeacherStudentsPage.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          '${students.length} '
          '${students.length == 1 ? 'student' : 'students'}',

          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),

        const SizedBox(height: 18),

        // IMPORTANT:
        // students is guaranteed to be a List here.
        ...students.map((student) => _studentCard(context, student)),
      ],
    );
  }

  // ================================================================
  // EXTRACT STUDENTS
  // ================================================================

  List<dynamic> _extractStudents(dynamic data) {
    if (data == null) {
      return [];
    }

    // API returned:
    //
    // [
    //   {...},
    //   {...}
    // ]

    if (data is List) {
      return List<dynamic>.from(data);
    }

    // API returned an object/map.

    if (data is Map) {
      // ------------------------------------------------------------
      // {
      //   "students": [...]
      // }
      // ------------------------------------------------------------

      final students = data['students'];

      if (students is List) {
        return List<dynamic>.from(students);
      }

      // ------------------------------------------------------------
      // {
      //   "data": [...]
      // }
      // ------------------------------------------------------------

      final result = data['data'];

      if (result is List) {
        return List<dynamic>.from(result);
      }

      // ------------------------------------------------------------
      // {
      //   "data": {
      //     "students": [...]
      //   }
      // }
      // ------------------------------------------------------------

      if (result is Map) {
        final nestedStudents = result['students'];

        if (nestedStudents is List) {
          return List<dynamic>.from(nestedStudents);
        }

        // Sometimes:
        //
        // {
        //   "data": {
        //     "data": [...]
        //   }
        // }

        final nestedData = result['data'];

        if (nestedData is List) {
          return List<dynamic>.from(nestedData);
        }
      }
    }

    return [];
  }

  // ================================================================
  // STUDENT CARD
  // ================================================================

  Widget _studentCard(BuildContext context, dynamic student) {
    final name = _studentName(student);
    final className = _studentClass(student);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: TeacherStudentsPage.primary.withOpacity(.08),
            child: const Icon(
              Icons.person_outline_rounded,
              color: TeacherStudentsPage.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TeacherStudentsPage.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  className,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              context.push('/teacher/students/details', extra: student);
            },
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: TeacherStudentsPage.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // STUDENT NAME
  // ================================================================

  String _studentName(dynamic student) {
    if (student is! Map) {
      return 'Unknown Student';
    }

    final value = _firstValue(student, [
      'name',
      'fullName',
      'studentName',
      'firstName',
    ]);

    if (value != null && value.trim().isNotEmpty) {
      return value;
    }

    // Handle APIs that separate first/last name.

    final firstName = _getString(student, 'firstName');

    final lastName = _getString(student, 'lastName');

    final combined = [
      if (firstName != null) firstName,
      if (lastName != null) lastName,
    ].join(' ').trim();

    if (combined.isNotEmpty) {
      return combined;
    }

    return 'Unknown Student';
  }

  // ================================================================
  // STUDENT CLASS
  // ================================================================

  String _studentClass(dynamic student) {
    if (student is! Map) {
      return 'No class';
    }

    return _firstValue(student, [
          'className',
          'classRoom',
          'class',
          'class_name',
        ]) ??
        'No class';
  }

  // ================================================================
  // STUDENT ID
  // ================================================================

  String _studentId(dynamic student) {
    if (student is! Map) {
      return 'N/A';
    }

    return _firstValue(student, ['studentId', 'id', 'studentID']) ?? 'N/A';
  }

  // ================================================================
  // FIRST STRING VALUE
  // ================================================================

  String? _firstValue(Map object, List<String> keys) {
    for (final key in keys) {
      final value = object[key];

      if (value != null) {
        final text = value.toString().trim();

        if (text.isNotEmpty) {
          return text;
        }
      }
    }

    return null;
  }

  // ================================================================
  // STRING VALUE
  // ================================================================

  String? _getString(Map object, String key) {
    final value = object[key];

    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    return text.isEmpty ? null : text;
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _errorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.red.shade300,
            ),

            const SizedBox(height: 16),

            const Text(
              'Unable to load students',
              textAlign: TextAlign.center,

              style: TextStyle(
                color: TeacherStudentsPage.textDark,
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

            ElevatedButton(
              onPressed: () {
                ref.invalidate(teacherStudentsProvider(selectedClassId));
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: TeacherStudentsPage.primary,

                foregroundColor: Colors.white,

                elevation: 0,

                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
