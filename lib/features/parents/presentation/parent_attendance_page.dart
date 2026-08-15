import 'package:app/features/parents/parent_preovider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ParentAttendancePage extends ConsumerWidget {
  final String studentId;

  const ParentAttendancePage({super.key, required this.studentId});

  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF7F7F7);
  static const Color textDark = Color(0xFF2F313D);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(parentChildProvider(studentId));

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textDark,
            size: 20,
          ),
        ),

        title: const Text(
          'Attendance',
          style: TextStyle(
            color: textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: childAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: primary)),

        error: (error, stackTrace) =>
            _errorState(context, error.toString(), ref),

        data: (child) {
          return RefreshIndicator(
            color: primary,

            onRefresh: () async {
              ref.invalidate(parentChildProvider(studentId));

              await ref.read(parentChildProvider(studentId).future);
            },

            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),

              padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),

              children: [
                // ========================================================
                // STUDENT HEADER
                // ========================================================
                _studentHeader(
                  name: child.fullName,
                  studentNumber: child.studentNumber,
                  className: child.className,
                ),

                const SizedBox(height: 20),

                // ========================================================
                // SUMMARY
                // ========================================================
                _sectionTitle(
                  'Attendance Summary',
                  'Current attendance performance',
                ),

                const SizedBox(height: 12),

                _summaryCard(name: child.fullName),

                const SizedBox(height: 25),

                // ========================================================
                // STATS
                // ========================================================
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _statCard(
                      icon: Icons.check_circle_outline_rounded,
                      value: '46',
                      title: 'Present',
                      color: Colors.green,
                    ),

                    _statCard(
                      icon: Icons.cancel_outlined,
                      value: '2',
                      title: 'Absent',
                      color: Colors.red,
                    ),

                    _statCard(
                      icon: Icons.access_time_rounded,
                      value: '1',
                      title: 'Late',
                      color: Colors.orange,
                    ),

                    _statCard(
                      icon: Icons.calendar_month_outlined,
                      value: '49',
                      title: 'School Days',
                      color: primary,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ========================================================
                // MONTHLY ATTENDANCE
                // ========================================================
                _sectionTitle(
                  'Monthly Attendance',
                  'Attendance performance by month',
                ),

                const SizedBox(height: 14),

                _monthlyCard(
                  month: 'January 2026',
                  percentage: '96%',
                  present: '20',
                  absent: '1',
                  color: Colors.green,
                ),

                _monthlyCard(
                  month: 'February 2026',
                  percentage: '94%',
                  present: '18',
                  absent: '1',
                  color: Colors.green,
                ),

                _monthlyCard(
                  month: 'March 2026',
                  percentage: '92%',
                  present: '16',
                  absent: '2',
                  color: Colors.orange,
                ),

                _monthlyCard(
                  month: 'April 2026',
                  percentage: '95%',
                  present: '19',
                  absent: '1',
                  color: Colors.green,
                ),

                const SizedBox(height: 28),

                // ========================================================
                // RECENT ATTENDANCE
                // ========================================================
                _sectionTitle('Recent Attendance', 'Latest attendance records'),

                const SizedBox(height: 14),

                _attendanceRecord(
                  date: 'Friday, Aug 14, 2026',
                  status: 'Present',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                ),

                _attendanceRecord(
                  date: 'Thursday, Aug 13, 2026',
                  status: 'Present',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                ),

                _attendanceRecord(
                  date: 'Wednesday, Aug 12, 2026',
                  status: 'Late',
                  icon: Icons.access_time_filled_rounded,
                  color: Colors.orange,
                ),

                _attendanceRecord(
                  date: 'Tuesday, Aug 11, 2026',
                  status: 'Present',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                ),

                _attendanceRecord(
                  date: 'Monday, Aug 10, 2026',
                  status: 'Absent',
                  icon: Icons.cancel_rounded,
                  color: Colors.red,
                ),

                _attendanceRecord(
                  date: 'Friday, Aug 7, 2026',
                  status: 'Present',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                ),

                _attendanceRecord(
                  date: 'Thursday, Aug 6, 2026',
                  status: 'Present',
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                ),

                const SizedBox(height: 25),

                // ========================================================
                // INFORMATION
                // ========================================================
                _informationCard(),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==============================================================
  // STUDENT HEADER
  // ==============================================================

  Widget _studentHeader({
    required String name,
    required String studentNumber,
    required String className,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: primary.withOpacity(.09),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: primary,
              size: 29,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '$className  •  $studentNumber',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),

                const SizedBox(height: 3),

                const Text(
                  '2025/2026 Academic Session',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // SUMMARY CARD
  // ==============================================================

  Widget _summaryCard({required String name}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, Color(0xFF1729B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            height: 85,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 78,
                  height: 78,
                  child: CircularProgressIndicator(
                    value: .92,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withOpacity(.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),

                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '92%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Attendance',
                      style: TextStyle(color: Colors.white70, fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Good Attendance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '$name has attended most school days this academic session.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 10),

                const Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 17,
                    ),

                    SizedBox(width: 5),

                    Text(
                      'Above school target',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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

  // ==============================================================
  // STAT CARD
  // ==============================================================

  Widget _statCard({
    required IconData icon,
    required String value,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 21),
          ),

          const Spacer(),

          Text(
            value,
            style: const TextStyle(
              color: textDark,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // MONTHLY CARD
  // ==============================================================

  Widget _monthlyCard({
    required String month,
    required String percentage,
    required String present,
    required String absent,
    required Color color,
  }) {
    final percentageValue = double.parse(percentage.replaceAll('%', '')) / 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: color,
                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      month,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '$present present  •  $absent absent',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                percentage,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentageValue,
              minHeight: 7,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // ATTENDANCE RECORD
  // ==============================================================

  Widget _attendanceRecord({
    required String date,
    required String status,
    required IconData icon,
    required Color color,
  }) {
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
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '2025/2026 Academic Session',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // INFORMATION
  // ==============================================================

  Widget _informationCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: primary.withOpacity(.05),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: primary.withOpacity(.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: primary, size: 22),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'Attendance records are updated by the school. '
              'If you notice an incorrect attendance record, '
              'please contact the school administration.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 11,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // SECTION TITLE
  // ==============================================================

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: textDark,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
      ],
    );
  }

  // ==============================================================
  // ERROR STATE
  // ==============================================================

  Widget _errorState(BuildContext context, String error, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red.shade400,
              size: 60,
            ),

            const SizedBox(height: 15),

            const Text(
              'Unable to Load Student',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),

            const SizedBox(height: 15),

            TextButton(
              onPressed: () {
                ref.invalidate(parentChildProvider(studentId));
              },
              child: const Text(
                'Try Again',
                style: TextStyle(color: primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
