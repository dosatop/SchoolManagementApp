import 'package:app/features/parents/parent_provider.dart';
import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ==================================================================
// PARENT: CHILD ATTENDANCE (current term)
// ==================================================================

class ParentAttendancePage extends ConsumerWidget {
  const ParentAttendancePage({
    super.key,
    required this.studentId,
    this.header,
  });

  final String studentId;

  /// Optional widget above the content (the dashboard passes a child
  /// switcher when this page is shown as a tab).
  final Widget? header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ParentChildTermParams(studentId);

    final childAsync = ref.watch(parentChildProvider(studentId));
    final async = ref.watch(parentChildAttendanceProvider(params));

    final data = async.valueOrNull;
    final summary = data is Map ? data['summary'] : null;
    final records = _parse(sList(data, ['records', 'attendance']));
    final term = sStr(data, ['term']);

    Future<void> refresh() async {
      ref.invalidate(parentChildAttendanceProvider(params));
      await sSafe(ref.read(parentChildAttendanceProvider(params).future));
    }

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar(
        'Attendance',
        subtitle: [
          if (childAsync.valueOrNull != null) childAsync.value!.fullName,
          if (term != null) term,
        ].join(' · '),
      ),
      body: _withHeader(header, RefreshIndicator(
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
                  'Attendance will show here once the teachers mark it this term.',
            );
          }

          final present = sNum(summary, ['present'])?.toInt() ??
              _count(records, 'present');
          final absent =
              sNum(summary, ['absent'])?.toInt() ?? _count(records, 'absent');
          final late =
              sNum(summary, ['late'])?.toInt() ?? _count(records, 'late');
          final excused = sNum(summary, ['excused'])?.toInt() ??
              _count(records, 'excused');

          final counted = present + absent + late;
          final rate = sNum(summary, ['attendancePercentage'])?.toDouble() ??
              (counted == 0 ? null : (present + late) / counted * 100);

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
                caption:
                    '${_message(rate)} · ${days.length} day${days.length == 1 ? '' : 's'} recorded',
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

              if (absent > 0) ...[
                const SizedBox(height: 14),
                _notice(
                  '$absent absence${absent == 1 ? '' : 's'} this term. '
                  'Contact the school if any of these look wrong.',
                ),
              ],

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
      )),
    );
  }

  Widget _notice(String text) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.orange.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

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
          if (records.length > 1 || records.first.remarks != null) ...[
            const SizedBox(height: 8),
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

  List<_Record> _parse(List<dynamic> raw) {
    final result = <_Record>[];

    for (final item in raw) {
      final day = sDay(item, ['attendanceDate', 'date']);
      final status = sStr(item, ['status']);
      if (day == null || status == null) continue;

      result.add(
        _Record(
          day: day,
          status: status[0].toUpperCase() + status.substring(1).toLowerCase(),
          subject: sStr(item, ['subjectName']),
          remarks: sStr(item, ['remarks']),
        ),
      );
    }

    return result;
  }

  int _count(List<_Record> records, String status) =>
      records.where((r) => r.status.toLowerCase() == status).length;

  String _message(double? rate) {
    if (rate == null) return 'No school days counted yet';
    if (rate >= 90) return 'Excellent';
    if (rate >= 75) return 'Good';
    if (rate >= 60) return 'Fair';
    return 'Needs attention';
  }
}

/// Puts an optional [header] (e.g. a child switcher) above [body].
Widget _withHeader(Widget? header, Widget body) {
  if (header == null) return body;
  return Column(children: [header, Expanded(child: body)]);
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