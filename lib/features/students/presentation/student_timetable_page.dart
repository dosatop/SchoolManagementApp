import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/presentation/widgets/student_ui.dart';
import 'package:flutter/material.dart';

// ==================================================================
// TIMETABLE
// ==================================================================
// NOTE: still sample data — there's no timetable endpoint yet. When
// there is, build `_week` from the API (same shape: weekday 1..5 ->
// list of periods) and nothing else on this page needs to change.
// ==================================================================

class _Period {
  const _Period(this.start, this.end, this.subject, {this.isBreak = false});

  /// Minutes from midnight.
  final int start;
  final int end;
  final String subject;
  final bool isBreak;
}

int _t(int h, int m) => h * 60 + m;

const _breakName = 'Break';

final Map<int, List<_Period>> _week = {
  DateTime.monday: [
    _Period(_t(8, 0), _t(9, 0), 'Mathematics'),
    _Period(_t(9, 0), _t(10, 0), 'English Language'),
    _Period(_t(10, 0), _t(10, 30), _breakName, isBreak: true),
    _Period(_t(10, 30), _t(11, 30), 'Basic Science'),
    _Period(_t(12, 0), _t(13, 0), 'Computer Studies'),
  ],
  DateTime.tuesday: [
    _Period(_t(8, 0), _t(9, 0), 'Social Studies'),
    _Period(_t(9, 0), _t(10, 0), 'Mathematics'),
    _Period(_t(10, 0), _t(10, 30), _breakName, isBreak: true),
    _Period(_t(10, 30), _t(11, 30), 'Civic Education'),
    _Period(_t(12, 0), _t(13, 0), 'English Language'),
  ],
  DateTime.wednesday: [
    _Period(_t(8, 0), _t(9, 0), 'Basic Science'),
    _Period(_t(9, 0), _t(10, 0), 'Mathematics'),
    _Period(_t(10, 0), _t(10, 30), _breakName, isBreak: true),
    _Period(_t(10, 30), _t(11, 30), 'Computer Studies'),
    _Period(_t(12, 0), _t(13, 0), 'Social Studies'),
  ],
  DateTime.thursday: [
    _Period(_t(8, 0), _t(9, 0), 'English Language'),
    _Period(_t(9, 0), _t(10, 0), 'Civic Education'),
    _Period(_t(10, 0), _t(10, 30), _breakName, isBreak: true),
    _Period(_t(10, 30), _t(11, 30), 'Mathematics'),
    _Period(_t(12, 0), _t(13, 0), 'Basic Science'),
  ],
  DateTime.friday: [
    _Period(_t(8, 0), _t(9, 0), 'Computer Studies'),
    _Period(_t(9, 0), _t(10, 0), 'Social Studies'),
    _Period(_t(10, 0), _t(10, 30), _breakName, isBreak: true),
    _Period(_t(10, 30), _t(11, 30), 'English Language'),
    _Period(_t(12, 0), _t(13, 0), 'Civic Education'),
  ],
};

class StudentTimetablePage extends StatefulWidget {
  const StudentTimetablePage({super.key});

  @override
  State<StudentTimetablePage> createState() => _StudentTimetablePageState();
}

class _StudentTimetablePageState extends State<StudentTimetablePage> {
  static const _days = [
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  ];

  static const _dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  late int _selected; // weekday 1..5

  @override
  void initState() {
    super.initState();
    final today = DateTime.now().weekday;
    _selected = _days.contains(today) ? today : DateTime.monday;
  }

  bool get _isToday => DateTime.now().weekday == _selected;

  @override
  Widget build(BuildContext context) {
    final periods = _week[_selected] ?? const <_Period>[];
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;

    final current = _isToday
        ? periods.where((p) => minutes >= p.start && minutes < p.end).firstOrNull
        : null;
    final next = _isToday
        ? periods.where((p) => p.start > minutes && !p.isBreak).firstOrNull
        : null;

    final lessons = periods.where((p) => !p.isBreak).length;

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar('Timetable', subtitle: 'Weekly class schedule'),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        children: [
          _dayPicker(),
          const SizedBox(height: 16),
          _hero(current: current, next: next, lessons: lessons),
          const SizedBox(height: 22),
          SectionHeader(
            _isToday ? 'Today' : _weekdayName(_selected),
            subtitle: '$lessons lesson${lessons == 1 ? '' : 's'}',
          ),
          const SizedBox(height: 12),
          if (periods.isEmpty)
            SoftCard(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No classes on this day.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            for (var i = 0; i < periods.length; i++)
              _periodRow(
                periods[i],
                index: i,
                isLast: i == periods.length - 1,
                isNow: identical(periods[i], current),
                isPast: _isToday && minutes >= periods[i].end,
              ),
        ],
      ),
    );
  }

  // ================================================================
  // DAY PICKER
  // ================================================================

  Widget _dayPicker() {
    final todayWeekday = DateTime.now().weekday;

    return Row(
      children: [
        for (var i = 0; i < _days.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selected = _days[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selected == _days[i]
                      ? StudentColors.primary
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selected == _days[i]
                        ? StudentColors.primary
                        : const Color(0xFFE6E8F0),
                  ),
                  boxShadow: _selected == _days[i]
                      ? [
                          BoxShadow(
                            color: StudentColors.primary.withValues(alpha: .25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      _dayShort[i],
                      style: TextStyle(
                        color: _selected == _days[i]
                            ? Colors.white
                            : StudentColors.textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: todayWeekday == _days[i]
                            ? (_selected == _days[i]
                                  ? Colors.white
                                  : StudentColors.primary)
                            : Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ================================================================
  // HERO (now / next)
  // ================================================================

  Widget _hero({_Period? current, _Period? next, required int lessons}) {
    final String title;
    final String subtitle;
    final IconData icon;

    if (!_isToday) {
      title = '${_weekdayName(_selected)}\'s classes';
      subtitle = '$lessons lessons scheduled';
      icon = Icons.event_note_rounded;
    } else if (current != null) {
      title = current.isBreak ? 'Break time ☕' : current.subject;
      subtitle = current.isBreak
          ? (next == null
                ? 'No more lessons today'
                : 'Next: ${next.subject} at ${_fmt(next.start)}')
          : 'Now · ends ${_fmt(current.end)}'
                '${next == null ? '' : ' · next ${next.subject}'}';
      icon = current.isBreak
          ? Icons.free_breakfast_rounded
          : Icons.play_circle_fill_rounded;
    } else if (next != null) {
      title = 'Next: ${next.subject}';
      subtitle = 'Starts at ${_fmt(next.start)}';
      icon = Icons.schedule_rounded;
    } else if (DateTime.now().weekday > DateTime.friday) {
      title = 'It\'s the weekend 🎉';
      subtitle = 'Here\'s Monday\'s schedule';
      icon = Icons.weekend_rounded;
    } else {
      title = 'School\'s out for today';
      subtitle = 'See you tomorrow!';
      icon = Icons.nights_stay_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: kStudentGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: StudentColors.primary.withValues(alpha: .22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 27),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .78),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // PERIOD ROW (timeline)
  // ================================================================

  Widget _periodRow(
    _Period p, {
    required int index,
    required bool isLast,
    required bool isNow,
    required bool isPast,
  }) {
    final color = p.isBreak
        ? Colors.grey.shade500
        : StudentColors.accents[_subjectIndex(p.subject) %
              StudentColors.accents.length];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time column
          SizedBox(
            width: 58,
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fmt(p.start, short: true),
                    style: TextStyle(
                      color: isNow
                          ? StudentColors.primary
                          : StudentColors.textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _ampm(p.start),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Timeline
          SizedBox(
            width: 22,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isNow ? StudentColors.primary : Colors.white,
                    border: Border.all(
                      color: isPast ? Colors.grey.shade300 : color,
                      width: 3,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Opacity(
                opacity: isPast ? .55 : 1,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: p.isBreak ? 10 : 14,
                  ),
                  decoration: BoxDecoration(
                    color: p.isBreak
                        ? const Color(0xFFF0F1F5)
                        : isNow
                        ? StudentColors.primary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: p.isBreak || isNow
                        ? null
                        : Border.all(color: const Color(0xFFE9EBF2)),
                    boxShadow: isNow
                        ? [
                            BoxShadow(
                              color: StudentColors.primary.withValues(
                                alpha: .25,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      if (!p.isBreak) ...[
                        Container(
                          width: 4,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isNow ? Colors.white : color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ] else ...[
                        Icon(
                          Icons.free_breakfast_outlined,
                          size: 17,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.subject,
                              style: TextStyle(
                                color: isNow
                                    ? Colors.white
                                    : p.isBreak
                                    ? Colors.grey.shade600
                                    : StudentColors.textDark,
                                fontSize: p.isBreak ? 12.5 : 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (!p.isBreak) ...[
                              const SizedBox(height: 3),
                              Text(
                                '${_fmt(p.start)} – ${_fmt(p.end)} · '
                                '${p.end - p.start} min',
                                style: TextStyle(
                                  color: isNow
                                      ? Colors.white.withValues(alpha: .8)
                                      : Colors.grey.shade600,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isNow)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'NOW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .8,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // HELPERS
  // ================================================================

  /// Same subject → same colour every day.
  final Map<String, int> _subjectColors = {};

  int _subjectIndex(String subject) =>
      _subjectColors.putIfAbsent(subject, () => _subjectColors.length);

  String _weekdayName(int weekday) =>
      const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ][weekday - 1];

  String _fmt(int minutes, {bool short = false}) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final time = '$h12:${m.toString().padLeft(2, '0')}';
    return short ? time : '$time ${_ampm(minutes)}';
  }

  String _ampm(int minutes) => minutes ~/ 60 < 12 ? 'AM' : 'PM';
}
