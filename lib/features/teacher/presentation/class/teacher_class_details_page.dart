import 'package:app/features/teacher/models/teacher_assignment_params.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TeacherClassDetailsPage extends ConsumerWidget {
  const TeacherClassDetailsPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.classId,
    required this.className,
  });

  final String subjectId;
  final String subjectName;
  final String classId;
  final String className;

  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ==============================================================
    // STUDENTS
    // ==============================================================

    final studentsAsync = ref.watch(teacherStudentsProvider(classId));

    // ==============================================================
    // ASSIGNMENTS
    // ==============================================================

    final assignmentsAsync = ref.watch(
      teacherClassAssignmentsProvider(
        TeacherAssignmentsParams(classId: classId, subjectId: subjectId),
      ),
    );

    // ==============================================================
    // ATTENDANCE
    // ==============================================================

    final attendanceAsync = ref.watch(
      teacherClassAttendanceProvider(
        TeacherClassAttendanceParams(classId: classId, subjectId: subjectId),
      ),
    );

    final studentCount = _extractStudentCount(studentsAsync.valueOrNull);

    final assignmentCount = _extractAssignmentCount(
      assignmentsAsync.valueOrNull,
    );

    final attendancePercentage = _extractAttendancePercentage(
      attendanceAsync.valueOrNull,
    );

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: textDark),
        ),

        title: const Text(
          'Class Details',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(teacherStudentsProvider(classId));

              ref.invalidate(
                teacherClassAssignmentsProvider(
                  TeacherAssignmentsParams(
                    classId: classId,
                    subjectId: subjectId,
                  ),
                ),
              );

              ref.invalidate(
                teacherClassAttendanceProvider(
                  TeacherClassAttendanceParams(
                    classId: classId,
                    subjectId: subjectId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.refresh_rounded, color: textDark),
          ),
        ],
      ),

      body: RefreshIndicator(
        color: primary,

        onRefresh: () async {
          await Future.wait([
            ref.refresh(teacherStudentsProvider(classId).future),
            ref.refresh(
              teacherClassAssignmentsProvider(
                TeacherAssignmentsParams(
                  classId: classId,
                  subjectId: subjectId,
                ),
              ).future,
            ),
            ref.refresh(
              teacherClassAttendanceProvider(
                TeacherClassAttendanceParams(
                  classId: classId,
                  subjectId: subjectId,
                ),
              ).future,
            ),
          ]);
        },

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 35),
          children: [
            // ==========================================================
            // CLASS HEADER
            // ==========================================================
            _classHeader(),

            const SizedBox(height: 20),

            // ==========================================================
            // QUICK STATS
            // ==========================================================
            _statsGrid(
              studentCount: studentCount,
              assignmentCount: assignmentCount,
              attendancePercentage: attendancePercentage,
              studentsLoading: studentsAsync.isLoading,
              assignmentsLoading: assignmentsAsync.isLoading,
              attendanceLoading: attendanceAsync.isLoading,
            ),

            const SizedBox(height: 25),

            // ==========================================================
            // CREATE ASSIGNMENT
            // ==========================================================
            _createAssignmentButton(context),

            const SizedBox(height: 25),

            // ==========================================================
            // MANAGE CLASS
            // ==========================================================
            const Text(
              'Manage Class',
              style: TextStyle(
                color: textDark,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _managementTile(
              context,
              icon: Icons.groups_outlined,
              title: 'Students',
              subtitle: 'View students in this class',
              color: Colors.purple,
              onTap: () {
                context.push(
                  '/teacher/classes/students',
                  extra: {
                    'subjectId': subjectId,
                    'subjectName': subjectName,
                    'classId': classId,
                    'className': className,
                  },
                );
              },
            ),

            _managementTile(
              context,
              icon: Icons.assignment_outlined,
              title: 'Assignments',
              subtitle: 'View and manage assignments',
              color: Colors.orange,
              onTap: () {
                context.push(
                  '/teacher/classes/assignments',
                  extra: {
                    'subjectId': subjectId,
                    'subjectName': subjectName,
                    'classId': classId,
                    'className': className,
                  },
                );
              },
            ),

            _managementTile(
              context,
              icon: Icons.fact_check_outlined,
              title: 'Attendance',
              subtitle: 'Take and view attendance',
              color: Colors.green,
              onTap: () {
                context.push(
                  '/teacher/classes/attendance',
                  extra: {
                    'subjectId': subjectId,
                    'subjectName': subjectName,
                    'classId': classId,
                    'className': className,
                  },
                );
              },
            ),

            _managementTile(
              context,
              icon: Icons.calendar_month_outlined,
              title: 'Timetable',
              subtitle: 'View class timetable',
              color: Colors.blue,
              onTap: () {
                context.push(
                  '/teacher/classes/timetable',
                  extra: {
                    'subjectId': subjectId,
                    'subjectName': subjectName,
                    'classId': classId,
                    'className': className,
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // CLASS HEADER
  // ================================================================

  Widget _classHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, Color(0xFF2437C5)],
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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subjectName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Row(
                  children: [
                    const Icon(
                      Icons.groups_outlined,
                      color: Colors.white70,
                      size: 15,
                    ),
                    const SizedBox(width: 5),

                    Flexible(
                      child: Text(
                        className,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // STATS
  // ================================================================

  Widget _statsGrid({
    required int? studentCount,
    required int? assignmentCount,
    required double? attendancePercentage,
    required bool studentsLoading,
    required bool assignmentsLoading,
    required bool attendanceLoading,
  }) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.groups_outlined,
            value: studentsLoading ? '...' : studentCount?.toString() ?? '—',
            label: 'Students',
            color: Colors.purple,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _statCard(
            icon: Icons.assignment_outlined,
            value: assignmentsLoading
                ? '...'
                : assignmentCount?.toString() ?? '—',
            label: 'Assignments',
            color: Colors.orange,
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _statCard(
            icon: Icons.percent_rounded,
            value: attendanceLoading
                ? '...'
                : attendancePercentage != null
                ? '${attendancePercentage.toStringAsFixed(0)}%'
                : '—',
            label: 'Attendance',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 19),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 9),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // CREATE ASSIGNMENT
  // ================================================================

  Widget _createAssignmentButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () {
          context.push(
            '/teacher/assignments/create',
            extra: {
              'subjectId': subjectId,
              'subjectName': subjectName,
              'classId': classId,
              'className': className,
            },
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        icon: const Icon(Icons.add_rounded, size: 21),
        label: const Text(
          'Create Assignment',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ================================================================
  // MANAGEMENT TILE
  // ================================================================

  Widget _managementTile(
    BuildContext context, {
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
                  child: Icon(icon, color: color, size: 21),
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
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
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
  // EXTRACT STUDENT COUNT
  // ================================================================

  int? _extractStudentCount(dynamic data) {
    if (data == null) {
      return null;
    }

    if (data is List) {
      return data.length;
    }

    if (data is Map) {
      final students = data['students'];

      if (students is List) {
        return students.length;
      }

      final dataValue = data['data'];

      if (dataValue is List) {
        return dataValue.length;
      }

      if (dataValue is Map) {
        final nestedStudents = dataValue['students'];

        if (nestedStudents is List) {
          return nestedStudents.length;
        }
      }

      final count = _extractNumber(data, [
        'count',
        'total',
        'studentCount',
        'totalStudents',
      ]);

      if (count != null) {
        return count.toInt();
      }
    }

    return null;
  }

  // ================================================================
  // EXTRACT ASSIGNMENT COUNT
  // ================================================================

  int? _extractAssignmentCount(dynamic data) {
    if (data == null) {
      return null;
    }

    if (data is List) {
      return data.length;
    }

    if (data is Map) {
      final assignments = data['assignments'];

      if (assignments is List) {
        return assignments.length;
      }

      final dataValue = data['data'];

      if (dataValue is List) {
        return dataValue.length;
      }

      if (dataValue is Map) {
        final nestedAssignments = dataValue['assignments'];

        if (nestedAssignments is List) {
          return nestedAssignments.length;
        }
      }

      final count = _extractNumber(data, [
        'count',
        'total',
        'assignmentCount',
        'totalAssignments',
      ]);

      if (count != null) {
        return count.toInt();
      }
    }

    return null;
  }

  // ================================================================
  // EXTRACT ATTENDANCE PERCENTAGE
  // ================================================================

  double? _extractAttendancePercentage(dynamic data) {
    if (data == null) {
      return null;
    }

    // If the API directly returns a list of
    // attendance records, calculate the percentage.
    if (data is List) {
      return _calculateAttendancePercentage(data);
    }

    if (data is Map) {
      // First check if the API already provides
      // a calculated percentage.
      final directPercentage = _extractNumber(data, [
        'attendancePercentage',
        'attendanceRate',
        'percentage',
        'rate',
      ]);

      if (directPercentage != null) {
        return directPercentage.clamp(0, 100).toDouble();
      }

      // Check common summary structures.
      final summary = data['summary'];

      if (summary is Map) {
        final summaryPercentage = _extractNumber(summary, [
          'attendancePercentage',
          'attendanceRate',
          'percentage',
          'rate',
        ]);

        if (summaryPercentage != null) {
          return summaryPercentage.clamp(0, 100).toDouble();
        }

        final present = _extractNumber(summary, [
          'present',
          'presentCount',
          'totalPresent',
        ]);

        final total = _extractNumber(summary, [
          'total',
          'totalAttendance',
          'totalRecords',
        ]);

        if (present != null && total != null && total > 0) {
          return ((present / total) * 100).clamp(0, 100).toDouble();
        }
      }

      // Check attendance list.
      final attendance = data['attendance'];

      if (attendance is List) {
        return _calculateAttendancePercentage(attendance);
      }

      final dataValue = data['data'];

      if (dataValue is List) {
        return _calculateAttendancePercentage(dataValue);
      }

      if (dataValue is Map) {
        final nestedPercentage = _extractAttendancePercentage(dataValue);

        if (nestedPercentage != null) {
          return nestedPercentage;
        }
      }
    }

    return null;
  }

  // ================================================================
  // CALCULATE ATTENDANCE FROM RECORDS
  // ================================================================

  double? _calculateAttendancePercentage(List records) {
    if (records.isEmpty) {
      return 0;
    }

    int present = 0;
    int total = 0;

    for (final record in records) {
      if (record is! Map) {
        continue;
      }

      final status = record['status']?.toString().toLowerCase();

      if (status == null) {
        continue;
      }

      total++;

      if (status == 'present' || status == 'p' || status == 'attended') {
        present++;
      }
    }

    if (total == 0) {
      return null;
    }

    return ((present / total) * 100).clamp(0, 100).toDouble();
  }

  // ================================================================
  // NUMBER HELPER
  // ================================================================

  num? _extractNumber(Map object, List<String> keys) {
    for (final key in keys) {
      final value = object[key];

      if (value is num) {
        return value;
      }

      if (value != null) {
        final parsed = num.tryParse(value.toString());

        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }
}
