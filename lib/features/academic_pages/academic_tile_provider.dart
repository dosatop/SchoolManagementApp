import 'package:app/core/Models/academic_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final academicTileProvider =
    AsyncNotifierProvider<AcademicTileNotifier, List<AcademicTile>>(
      AcademicTileNotifier.new,
    );

class AcademicTileNotifier extends AsyncNotifier<List<AcademicTile>> {
  @override
  Future<List<AcademicTile>> build() async {
    return loadAcademicTiles();
  }

  Future<List<AcademicTile>> loadAcademicTiles() async {
    await Future.delayed(Duration(seconds: 2));

    return [
      AcademicTile(
        name: 'Students',
        imageUrl: 'assets/academics/reading.png',
        route: '/students',
      ),
      AcademicTile(
        name: 'Teacher',
        imageUrl: 'assets/academics/teacher.png',
        route: '/teacher',
      ),
      AcademicTile(
        name: 'Attendance',
        imageUrl: 'assets/academics/attendance.png',
        route: '/attendance',
      ),
      AcademicTile(
        name: 'Syllabus',
        imageUrl: 'assets/academics/syllabus.png',
        route: '/syllabus',
      ),
      AcademicTile(
        name: 'Time Table',
        imageUrl: 'assets/academics/timetable.png',
        route: '/timetable',
      ),
      AcademicTile(
        name: 'Assignments',
        imageUrl: 'assets/academics/assignment.png',
        route: '/assignment',
      ),
      AcademicTile(
        name: 'Exams',
        imageUrl: 'assets/academics/exam.png',
        route: '/exam',
      ),
      AcademicTile(
        name: 'Results',
        imageUrl: 'assets/academics/result.png',
        route: '/results-management',
      ),
      AcademicTile(
        name: 'Fees',
        imageUrl: 'assets/academics/fees.png',
        route: '/fees',
      ),
      AcademicTile(
        name: 'Events',
        imageUrl: 'assets/academics/events.png',
        route: '/event',
      ),
      AcademicTile(
        name: 'Inbox',
        imageUrl: 'assets/academics/inbox.png',
        route: '/inbox',
      ),
      AcademicTile(
        name: 'Ask Doubt',
        imageUrl: 'assets/academics/ask.png',
        route: '/ask',
      ),
    ];
  }

  void addAcademicTile(AcademicTile tile) {
    final currentTiles = state.value ?? [];

    state = AsyncData([...currentTiles, tile]);
  }

  void removeAcademicTile(AcademicTile tile) {
    final currentTiles = state.value ?? [];

    state = AsyncData([...currentTiles.where((item) => item != tile)]);
  }

  void setAcademicTiles(List<AcademicTile> tiles) {
    state = AsyncData([...tiles]);
  }

  void clearAcademicTiles() {
    state = const AsyncData([]);
  }
}
