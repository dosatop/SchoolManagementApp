import 'package:app/features/students/presentation/widgets/student_common.dart';
import 'package:app/features/students/provider/students_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StudentSubjectsPage extends ConsumerWidget {
  const StudentSubjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(studentSubjectsProvider);
    final subjects = sList(async.valueOrNull, ['subjects']);

    Future<void> refresh() async {
      ref.invalidate(studentSubjectsProvider);
      await sSafe(ref.read(studentSubjectsProvider.future));
    }

    return Scaffold(
      backgroundColor: StudentColors.background,
      appBar: studentAppBar(
        'My Subjects',
        subtitle: async.hasValue
            ? '${subjects.length} subject${subjects.length == 1 ? '' : 's'}'
            : null,
      ),
      body: RefreshIndicator(
        color: StudentColors.primary,
        onRefresh: refresh,
        child: () {
          if (async.isLoading && !async.hasValue) {
            return const StudentLoadingView();
          }

          if (async.hasError && !async.hasValue) {
            return StudentErrorView(
              error: async.error!,
              onRetry: refresh,
              title: 'Unable to load subjects',
            );
          }

          if (subjects.isEmpty) {
            return const StudentEmptyView(
              icon: Icons.menu_book_outlined,
              title: 'No subjects yet',
              message: 'Subjects added to your class will show up here.',
            );
          }

          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _subjectCard(
              subjects[index],
              StudentColors.accents[index % StudentColors.accents.length],
            ),
          );
        }(),
      ),
    );
  }

  Widget _subjectCard(dynamic item, Color color) {
    final name = sStr(item, ['subjectName', 'name', 'title']) ?? 'Subject';
    final code = sStr(item, ['code', 'subjectCode']);
    final teacher = sStr(item, ['teacherName', 'teacher', 'teacherFullName']);
    final department = sStr(item, ['departmentName', 'department']);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(15),
            ),
            alignment: Alignment.center,
            child: Text(
              _abbrev(code ?? name),
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
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
                    color: StudentColors.textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (code != null || department != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (code != null) code,
                      if (department != null) department,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
                if (teacher != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          teacher,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "LIV" from a code, or the first letters of the name.
  String _abbrev(String text) {
    final clean = text.trim();
    if (clean.length <= 4 && !clean.contains(' ')) return clean.toUpperCase();

    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final letters = words.take(3).map((w) => w[0]).join();
    return letters.toUpperCase();
  }
}