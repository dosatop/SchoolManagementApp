import 'package:app/Models/academic_tile.dart';
import 'package:flutter/foundation.dart';

class AcademicTileProvider with ChangeNotifier {
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  final List<AcademicTile> _academicTiles = [];

  List<AcademicTile> get academicTiles => _academicTiles;
  Future<void> loadAcademicTiles() async {
    _isLoading = true;
    notifyListeners();

    // Simulating API call
    await Future.delayed(const Duration(seconds: 2));

    _academicTiles.clear();

    _academicTiles.addAll([
      AcademicTile(
        name: "Students",
        imageUrl: "lib/assets/academics/reading.png",
      ),
      AcademicTile(
        name: "Teacher",
        imageUrl: "lib/assets/academics/teacher.png",
      ),
      AcademicTile(
        name: "Attendance",
        imageUrl: "lib/assets/academics/attendance.png",
      ),
      AcademicTile(
        name: "Syllabus",
        imageUrl: "lib/assets/academics/syllabus.png",
      ),
      AcademicTile(
        name: "Time Table",
        imageUrl: "lib/assets/academics/timetable.png",
      ),
      AcademicTile(
        name: "Assignments",
        imageUrl: "lib/assets/academics/assignment.png",
      ),
      AcademicTile(name: "Exams", imageUrl: "lib/assets/academics/exam.png"),
      AcademicTile(
        name: "Results",
        imageUrl: "lib/assets/academics/result.png",
      ),
      AcademicTile(name: "Fees", imageUrl: "lib/assets/academics/fees.png"),
      AcademicTile(name: "Events", imageUrl: "lib/assets/academics/events.png"),
      AcademicTile(name: "Inbox", imageUrl: "lib/assets/academics/inbox.png"),
      AcademicTile(name: "Ask Doubt", imageUrl: "lib/assets/academics/ask.png"),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  void addAcademicTile(AcademicTile tile) {
    _academicTiles.add(tile);
    notifyListeners();
  }

  void removeAcademicTile(AcademicTile tile) {
    _academicTiles.remove(tile);
    notifyListeners();
  }

  void setAcademicTiles(List<AcademicTile> tiles) {
    _academicTiles.clear();
    _academicTiles.addAll(tiles);
    notifyListeners();
  }

  void clearAcademicTiles() {
    _academicTiles.clear();
    notifyListeners();
  }
}
