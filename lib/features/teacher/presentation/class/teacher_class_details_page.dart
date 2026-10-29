import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/teacher/models/teacher_assignment_params.dart';
import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TeacherClassDetailsPage extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<TeacherClassDetailsPage> createState() =>
      _TeacherClassDetailsPageState();
}

class _TeacherClassDetailsPageState
    extends ConsumerState<TeacherClassDetailsPage> {
  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  // ================================================================
  // PROVIDER PARAMS
  // ================================================================
  // Created once and reused for watch / invalidate / refresh.
  // A new params object on every build makes a family provider treat
  // it as a new key (endless loading, repeated API calls) unless the
  // params class overrides == and hashCode. Reusing one instance
  // avoids that either way, and guarantees refresh hits the same
  // provider the page is watching.

  late final TeacherAssignmentsParams _assignmentsParams;
  late final TeacherClassAttendanceParams _attendanceParams;

  String get subjectId => widget.subjectId;
  String get subjectName => widget.subjectName;
  String get classId => widget.classId;
  String get className => widget.className;

  Map<String, String> get _routeExtra => {
    'subjectId': subjectId,
    'subjectName': subjectName,
    'classId': classId,
    'className': className,
  };

  @override
  void initState() {
    super.initState();

    _assignmentsParams = TeacherAssignmentsParams(
      classId: widget.classId,
      subjectId: widget.subjectId,
    );

    _attendanceParams = TeacherClassAttendanceParams(
      classId: widget.classId,
      subjectId: widget.subjectId,
    );
  }

  // ================================================================
  // REFRESH
  // ================================================================

  void _invalidateAll() {
    ref.invalidate(teacherStudentsProvider(classId));
    ref.invalidate(teacherClassAssignmentsProvider(_assignmentsParams));
    ref.invalidate(teacherClassAttendanceProvider(_attendanceParams));
  }

  Future<void> _refreshAll() async {
    _invalidateAll();

    // Wait for all three, but don't let one failure break the others.
    // Errors are shown as '—' in the stat cards.
    await Future.wait([
      ref
          .read(teacherStudentsProvider(classId).future)
          .then((_) {}, onError: (_) {}),
      ref
          .read(teacherClassAssignmentsProvider(_assignmentsParams).future)
          .then((_) {}, onError: (_) {}),
      ref
          .read(teacherClassAttendanceProvider(_attendanceParams).future)
          .then((_) {}, onError: (_) {}),
    ]);
  }

  // Push a sub-page and refresh the stats when the teacher comes back,
  // so new assignments / attendance show up immediately.
  void _openAndRefresh(String route) {
    context.push(route, extra: _routeExtra).then((_) {
      if (mounted) {
        _invalidateAll();
        ref.invalidate(teacherResultsProvider);
      }
    });
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(teacherStudentsProvider(classId));

    final assignmentsAsync = ref.watch(
      teacherClassAssignmentsProvider(_assignmentsParams),
    );

    final attendanceAsync = ref.watch(
      teacherClassAttendanceProvider(_attendanceParams),
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
            onPressed: _invalidateAll,
            icon: const Icon(Icons.refresh_rounded, color: textDark),
          ),
        ],
      ),

      body: RefreshIndicator(
        color: primary,

        onRefresh: _refreshAll,

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
              studentsLoading:
                  studentsAsync.isLoading && !studentsAsync.hasValue,
              assignmentsLoading:
                  assignmentsAsync.isLoading && !assignmentsAsync.hasValue,
              attendanceLoading:
                  attendanceAsync.isLoading && !attendanceAsync.hasValue,
            ),

            const SizedBox(height: 25),

            // ==========================================================
            // CREATE ASSIGNMENT
            // ==========================================================
            _createAssignmentButton(),

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
              icon: Icons.groups_outlined,
              title: 'Students',
              subtitle: 'View students in this class',
              color: Colors.purple,
              onTap: () => _openAndRefresh('/teacher/classes/students'),
            ),

            _managementTile(
              icon: Icons.assignment_outlined,
              title: 'Assignments',
              subtitle: 'View and manage assignments',
              color: Colors.orange,
              onTap: () => _openAndRefresh('/teacher/classes/assignments'),
            ),

            _managementTile(
              icon: Icons.fact_check_outlined,
              title: 'Attendance',
              subtitle: 'Take and view attendance',
              color: Colors.green,
              onTap: () => _openAndRefresh('/teacher/classes/attendance'),
            ),

            _managementTile(
              icon: Icons.grading_rounded,
              title: 'Results',
              subtitle: 'Enter test and exam scores for $subjectName',
              color: Colors.indigo,
              onTap: () => _openAndRefresh('/teacher/results/entry'),
            ),

            _managementTile(
              icon: Icons.calendar_month_outlined,
              title: 'Timetable',
              subtitle: 'View class timetable',
              color: Colors.blue,
              onTap: () => _openAndRefresh('/teacher/classes/timetable'),
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
            color: primary.withValues(alpha: .18),
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
              color: Colors.white.withValues(alpha: .15),
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
              color: color.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 19),
          ),

          const SizedBox(height: 8),

          if (value == '...')
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Shimmer(child: ShimmerBox(width: 30, height: 17)),
            )
          else
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

  Widget _createAssignmentButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: () => _openAndRefresh('/teacher/assignments/create'),
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
                    color: color.withValues(alpha: .09),
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

    if (data is List) {
      return _calculateAttendancePercentage(data);
    }

    if (data is Map) {
      final directPercentage = _extractNumber(data, [
        'attendancePercentage',
        'attendanceRate',
        'percentage',
        'rate',
      ]);

      if (directPercentage != null) {
        return directPercentage.clamp(0, 100).toDouble();
      }

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
  // No records yet -> null (shows '—') instead of a misleading 0%.
  // Rate = (Present + Late) / (Present + Absent + Late).
  // Excused and Holiday don't count either way.
  // Only this subject's records count (class-register marks are a
  // different attendance type).

  double? _calculateAttendancePercentage(List records) {
    if (records.isEmpty) {
      return null;
    }

    int present = 0;
    int total = 0;

    for (final record in records) {
      if (record is! Map) {
        continue;
      }

      final recordSubject = record['subjectId']?.toString().toLowerCase();
      if (recordSubject != null && recordSubject != subjectId.toLowerCase()) {
        continue;
      }
      if (recordSubject == null) {
        continue; // class register, not this subject
      }

      final status = record['status']?.toString().toLowerCase();

      if (status == null) {
        continue;
      }

      if (status == 'present' || status == 'late') {
        present++;
        total++;
      } else if (status == 'absent') {
        total++;
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
