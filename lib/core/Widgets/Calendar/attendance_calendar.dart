import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class AttendanceCalendar extends StatefulWidget {
  const AttendanceCalendar({super.key});

  @override
  State<AttendanceCalendar> createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<AttendanceCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Attendance status for specific dates
  final Map<DateTime, String> attendance = {
    DateTime(2026, 8, 3): 'present',
    DateTime(2026, 8, 4): 'early-off',
    DateTime(2026, 8, 5): 'absent',
    DateTime(2026, 8, 6): 'late',
    DateTime(2026, 8, 7): 'festival',
    DateTime(2026, 8, 10): 'absent',
    DateTime(2026, 8, 11): 'present',
  };

  String? _getAttendance(DateTime day) {
    return attendance[DateTime(day.year, day.month, day.day)];
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.yellow;
      case 'early-off':
        return Colors.purple;
      case 'festival':
        return Colors.blue;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,

          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },

          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },

          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,

            todayDecoration: BoxDecoration(
              color: const Color(0xFF091993).withOpacity(0.3),
              shape: BoxShape.circle,
            ),

            selectedDecoration: const BoxDecoration(
              color: Color(0xFF091993),
              shape: BoxShape.circle,
            ),

            weekendTextStyle: const TextStyle(color: Colors.red),
          ),

          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),

          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final status = _getAttendance(day);

              if (status == null) {
                return null;
              }

              return Container(
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStatusColor(status),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 15),

        // Legend
        SizedBox(
          width: double.infinity,
          // height: ,
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _legend(color: Colors.green, text: 'Present'),
              const SizedBox(width: 10),
              _legend(color: Colors.red, text: 'Absent'),
              const SizedBox(width: 10),
              _legend(color: Colors.yellow, text: 'Late'),
              _legend(color: Colors.red, text: 'Absent'),
              const SizedBox(width: 10),
              _legend(color: Colors.orange, text: 'early-off'),
              _legend(color: Colors.blue, text: 'festival'),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Selected date information
        if (_selectedDay != null)
          Text(
            '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}'
            ' - ${_getAttendance(_selectedDay!) ?? 'No record'}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
      ],
    );
  }

  Widget _legend({required Color color, required String text}) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(text),
      ],
    );
  }
}
