import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/presentation/widgets/student_ui.dart';
import 'package:app/features/students/provider/students_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Class register (class teacher, no subject) vs subject attendance.
enum _Kind { all, classRegister, subjects }

class StudentAttendancePage extends ConsumerStatefulWidget {
  const StudentAttendancePage({super.key});

  @override
  ConsumerState<StudentAttendancePage> createState() =>
      _StudentAttendancePageState();
}

class _StudentAttendancePageState extends ConsumerState<StudentAttendancePage> {
  static const _params = StudentTermParams.current;

  _Kind _kind = _Kind.all;
  String? _status; // null = every status

  Future<void> _refresh() async {
    ref.invalidate(studentAttendanceProvider(_params));
    await sSafe(ref.read(studentAttendanceProvider(_params).future));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(studentAttendanceProvider(_params));
    final all = _parse(sList(async.valueOrNull, ['attendance', 'records']));

    final classRecords = all.where((r) => r.isClassRegister).toList();
    final subjectRecords = all.where((r) => !r.isClassRegister).toList();

    final byKind = switch (_kind) {
      _Kind.all => all,
      _Kind.classRegister => classRecords,
      _Kind.subjects => subjectRecords,
    };

    final visible = _status == null
        ? byKind
        : byKind.where((r) => r.status.toLowerCase() == _status).toList();

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar('Attendance', subtitle: 'This term'),
      body: RefreshIndicator(
        color: StudentColors.primary,
        onRefresh: _refresh,
        child: () {
          if (async.isLoading && !async.hasValue) {
            return const StudentLoadingView(layout: LoadingLayout.summary);
          }

          if (async.hasError && !async.hasValue) {
            return StudentErrorView(
              error: async.error!,
              onRetry: _refresh,
              title: 'Unable to load attendance',
            );
          }

          if (all.isEmpty) {
            return const StudentEmptyView(
              icon: Icons.fact_check_outlined,
              title: 'No attendance yet',
              message:
                  'Your attendance will show here once your teachers mark it.',
            );
          }

          final stats = _Stats.of(byKind);

          // Newest first, grouped by month then day.
          final byDay = <DateTime, List<_Record>>{};
          for (final r in visible) {
            byDay.putIfAbsent(r.day, () => []).add(r);
          }
          final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
            children: [
              _summary(stats),

              const SizedBox(height: 14),

              // Class register vs subject attendance
              if (classRecords.isNotEmpty && subjectRecords.isNotEmpty) ...[
                _kindSwitch(classRecords.length, subjectRecords.length),
                const SizedBox(height: 12),
              ],

              // Status filter
              PillTabs<String?>(
                padding: EdgeInsets.zero,
                selected: _status,
                onChanged: (s) => setState(() => _status = s),
                tabs: [
                  PillTab(null, 'All', count: byKind.length),
                  PillTab(
                    'present',
                    'Present',
                    count: stats.present,
                    color: Colors.green.shade600,
                  ),
                  PillTab(
                    'absent',
                    'Absent',
                    count: stats.absent,
                    color: Colors.red.shade600,
                  ),
                  PillTab(
                    'late',
                    'Late',
                    count: stats.late,
                    color: Colors.orange.shade700,
                  ),
                  if (stats.excused > 0)
                    PillTab(
                      'excused',
                      'Excused',
                      count: stats.excused,
                      color: Colors.blueGrey,
                    ),
                ],
              ),

              const SizedBox(height: 20),

              if (days.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 30),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_busy_rounded,
                        size: 44,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No ${_status ?? ''} records',
                        style: const TextStyle(
                          color: StudentColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._history(days, byDay),
            ],
          );
        }(),
      ),
    );
  }

  // ================================================================
  // SUMMARY
  // ================================================================

  Widget _summary(_Stats s) {
    final rate = s.rate;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: kStudentGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: StudentColors.primary.withValues(alpha: .24),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ProgressRing(
                value: (rate ?? 0) / 100,
                size: 92,
                stroke: 9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      rate == null ? '—' : '${rate.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'attended',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .7),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rate == null ? 'No marked days' : _message(rate),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.days} day${s.days == 1 ? '' : 's'} recorded'
                      '${s.streak > 1 ? ' · ${s.streak}-day streak 🔥' : ''}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .75),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                HeroStat('Present', '${s.present}'),
                HeroStat('Absent', '${s.absent}'),
                HeroStat('Late', '${s.late}'),
                HeroStat('Excused', '${s.excused}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kindSwitch(int classCount, int subjectCount) {
    Widget option(_Kind kind, String label, IconData icon) {
      final selected = _kind == kind;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _kind = kind),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? StudentColors.primary
                      : Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? StudentColors.primary
                        : Colors.grey.shade700,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EBF3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          option(_Kind.all, 'All', Icons.layers_outlined),
          option(_Kind.classRegister, 'Class', Icons.class_outlined),
          option(_Kind.subjects, 'Subjects', Icons.menu_book_outlined),
        ],
      ),
    );
  }

  // ================================================================
  // HISTORY
  // ================================================================

  List<Widget> _history(List<DateTime> days, Map<DateTime, List<_Record>> byDay) {
    final widgets = <Widget>[];
    String? month;

    for (final day in days) {
      final m = '${_monthsLong[day.month - 1]} ${day.year}';
      if (m != month) {
        month = m;
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 10, top: widgets.isEmpty ? 0 : 10),
            child: Text(
              m.toUpperCase(),
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        );
      }
      widgets.add(_dayCard(day, byDay[day]!));
      widgets.add(const SizedBox(height: 10));
    }

    return widgets;
  }

  Widget _dayCard(DateTime day, List<_Record> records) {
    final single = records.length == 1;
    final main = records.first;
    final color = _statusColor(single ? main.status : _worst(records));

    return SoftCard(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                sMonths[day.month - 1].toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: .5,
                                ),
                              ),
                              Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sDayLabel(day),
                                style: const TextStyle(
                                  color: StudentColors.textDark,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                single
                                    ? (main.subject ?? 'Class register')
                                    : '${records.length} entries',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (single) StatusChip(main.status),
                      ],
                    ),
                    if (!single || main.remarks != null) ...[
                      const SizedBox(height: 8),
                      for (final r in records)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 58),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!single)
                                      Text(
                                        r.subject ?? 'Class register',
                                        style: const TextStyle(
                                          color: StudentColors.textDark,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    if (r.remarks != null)
                                      Text(
                                        r.remarks!,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 11.5,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!single) StatusChip(r.status),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // HELPERS
  // ================================================================

  static const _monthsLong = [
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

  static const _numericStatus = [
    'Present',
    'Absent',
    'Late',
    'Excused',
    'Holiday',
  ];

  List<_Record> _parse(List<dynamic> raw) {
    final result = <_Record>[];

    for (final item in raw) {
      final day = sDay(item, ['attendanceDate', 'date']);
      var status =
          sStr(item, ['statusName', 'status', 'attendanceStatus']) ?? '';
      if (day == null || status.isEmpty) continue;

      // Some endpoints send the enum as a number.
      final asInt = int.tryParse(status);
      if (asInt != null) {
        status = asInt >= 0 && asInt < _numericStatus.length
            ? _numericStatus[asInt]
            : status;
      }

      result.add(
        _Record(
          day: day,
          status: _normalise(status),
          subject: sStr(item, ['subjectName', 'subject']),
          subjectId: sStr(item, ['subjectId']),
          remarks: sStr(item, ['remarks', 'remark']),
        ),
      );
    }

    return result;
  }

  String _normalise(String status) {
    final s = status.trim().toLowerCase();
    if (s.isEmpty) return status;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _worst(List<_Record> records) {
    const order = ['absent', 'late', 'excused', 'holiday', 'present'];
    for (final s in order) {
      if (records.any((r) => r.status.toLowerCase() == s)) return s;
    }
    return records.first.status;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green.shade600;
      case 'absent':
        return Colors.red.shade600;
      case 'late':
        return Colors.orange.shade700;
      case 'excused':
        return Colors.blueGrey;
      case 'holiday':
        return Colors.purple;
      default:
        return Colors.grey.shade500;
    }
  }

  String _message(double rate) {
    if (rate >= 90) return 'Excellent attendance';
    if (rate >= 75) return 'Good attendance';
    if (rate >= 60) return 'Fair attendance';
    return 'Needs improvement';
  }
}

// ==================================================================
// MODELS
// ==================================================================

class _Record {
  const _Record({
    required this.day,
    required this.status,
    this.subject,
    this.subjectId,
    this.remarks,
  });

  final DateTime day;
  final String status;
  final String? subject;
  final String? subjectId;
  final String? remarks;

  /// Class register = marked by the class teacher, no subject.
  bool get isClassRegister => subjectId == null && subject == null;
}

class _Stats {
  const _Stats({
    required this.present,
    required this.absent,
    required this.late,
    required this.excused,
    required this.days,
    required this.streak,
  });

  final int present;
  final int absent;
  final int late;
  final int excused;
  final int days;

  /// Consecutive most-recent days without an absence.
  final int streak;

  /// (Present + Late) / (Present + Absent + Late). Excused/Holiday ignored.
  double? get rate {
    final counted = present + absent + late;
    return counted == 0 ? null : (present + late) / counted * 100;
  }

  static _Stats of(List<_Record> records) {
    int count(String s) =>
        records.where((r) => r.status.toLowerCase() == s).length;

    final byDay = <DateTime, List<_Record>>{};
    for (final r in records) {
      byDay.putIfAbsent(r.day, () => []).add(r);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    var streak = 0;
    for (final d in days) {
      final list = byDay[d]!;
      final absent = list.any((r) => r.status.toLowerCase() == 'absent');
      final attended = list.any(
        (r) => ['present', 'late'].contains(r.status.toLowerCase()),
      );
      if (absent) break;
      if (attended) streak++;
    }

    return _Stats(
      present: count('present'),
      absent: count('absent'),
      late: count('late'),
      excused: count('excused'),
      days: days.length,
      streak: streak,
    );
  }
}
