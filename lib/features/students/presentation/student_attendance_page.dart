import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/provider/students_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentAttendancePage extends ConsumerWidget {
  const StudentAttendancePage({super.key});

  static const _params = StudentTermParams.current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentAttendanceProvider(_params));
    final records = _parse(sList(async.valueOrNull, ['attendance']));

    Future<void> refresh() async {
      ref.invalidate(studentAttendanceProvider(_params));
      await sSafe(ref.read(studentAttendanceProvider(_params).future));
    }

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar('Attendance', subtitle: 'This term'),
      body: RefreshIndicator(
        color: StudentColors.primary,
        onRefresh: refresh,
        child: () {
          if (async.isLoading && !async.hasValue) {
            return const StudentLoadingView(layout: LoadingLayout.summary);
          }

          if (async.hasError && !async.hasValue) {
            return StudentErrorView(
              error: async.error!,
              onRetry: refresh,
              title: 'Unable to load attendance',
            );
          }

          if (records.isEmpty) {
            return const StudentEmptyView(
              icon: Icons.fact_check_outlined,
              title: 'No attendance yet',
              message:
                  'Your attendance will show here once your teachers mark it.',
            );
          }

          final present = _count(records, 'present');
          final absent = _count(records, 'absent');
          final late = _count(records, 'late');
          final excused = _count(records, 'excused');

          // Late counts as attended; Excused doesn't count either way.
          final counted = present + absent + late;
          final rate = counted == 0 ? null : (present + late) / counted * 100;

          // Newest first, grouped by day.
          final byDay = <DateTime, List<_Record>>{};
          for (final r in records) {
            byDay.putIfAbsent(r.day, () => []).add(r);
          }
          final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            children: [
              StudentSummaryCard(
                label: 'Attendance rate',
                value: rate == null ? '—' : '${rate.toStringAsFixed(0)}%',
                caption: rate == null
                    ? '${days.length} day${days.length == 1 ? '' : 's'} recorded'
                    : '${_message(rate)} · ${days.length} day${days.length == 1 ? '' : 's'}',
                progress: rate == null ? null : rate / 100,
                icon: Icons.fact_check_outlined,
                footer: Row(
                  children: [
                    SummaryStat('Present', '$present'),
                    SummaryStat('Absent', '$absent'),
                    SummaryStat('Late', '$late'),
                    SummaryStat('Excused', '$excused'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'History',
                style: TextStyle(
                  color: StudentColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              for (final day in days) ...[
                _dayCard(day, byDay[day]!),
                const SizedBox(height: 10),
              ],
            ],
          );
        }(),
      ),
    );
  }

  // ================================================================
  // DAY CARD
  // ================================================================
  // One card per day. A day can have class attendance (no subject)
  // and/or per-subject attendance; each is listed as a row.

  Widget _dayCard(DateTime day, List<_Record> records) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 50,
                decoration: BoxDecoration(
                  color: StudentColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      sMonths[day.month - 1].toUpperCase(),
                      style: const TextStyle(
                        color: StudentColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                      ),
                    ),
                    Text(
                      '${day.day}',
                      style: const TextStyle(
                        color: StudentColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sWeekday(day),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (records.length == 1) StatusChip(records.first.status),
            ],
          ),

          // Several entries that day (class + subjects): list them.
          if (records.length > 1 || records.first.remarks != null) ...[
            const SizedBox(height: 10),
            for (final r in records)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const SizedBox(width: 58),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (records.length > 1)
                            Text(
                              r.subject ?? 'Class attendance',
                              style: const TextStyle(
                                color: StudentColors.textDark,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (r.remarks != null)
                            Text(
                              r.remarks!,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (records.length > 1) StatusChip(r.status),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ================================================================
  // HELPERS
  // ================================================================

  List<_Record> _parse(List<dynamic> raw) {
    final result = <_Record>[];

    for (final item in raw) {
      final day = sDay(item, ['attendanceDate', 'date']);
      final status = sStr(item, ['status', 'attendanceStatus']);
      if (day == null || status == null) continue;

      result.add(
        _Record(
          day: day,
          status: _normalise(status),
          subject: sStr(item, ['subjectName', 'subject']),
          remarks: sStr(item, ['remarks', 'remark']),
        ),
      );
    }

    return result;
  }

  String _normalise(String status) {
    final s = status.toLowerCase();
    if (s.isEmpty) return status;
    return s[0].toUpperCase() + s.substring(1);
  }

  int _count(List<_Record> records, String status) =>
      records.where((r) => r.status.toLowerCase() == status).length;

  String _message(double rate) {
    if (rate >= 90) return 'Excellent';
    if (rate >= 75) return 'Good';
    if (rate >= 60) return 'Fair';
    return 'Needs improvement';
  }
}

class _Record {
  const _Record({
    required this.day,
    required this.status,
    this.subject,
    this.remarks,
  });

  final DateTime day;
  final String status;
  final String? subject;
  final String? remarks;
}