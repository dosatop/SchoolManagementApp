import 'package:app/features/teacher/provider/teachers_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import the file where these providers are defined.
// import 'package:your_app/providers/teacher_provider.dart';

class TeacherClassStudentsPage extends ConsumerStatefulWidget {
  final String subjectId;
  final String subjectName;
  final String classId;
  final String className;

  const TeacherClassStudentsPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.classId,
    required this.className,
  });

  @override
  ConsumerState<TeacherClassStudentsPage> createState() =>
      _TeacherClassStudentsPageState();
}

class _TeacherClassStudentsPageState
    extends ConsumerState<TeacherClassStudentsPage> {
  final TextEditingController _searchController =
      TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // STUDENTS PROVIDER
  // ============================================================

  AsyncValue<dynamic> get _studentsAsync {
    return ref.watch(
      teacherStudentsProvider(widget.classId),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  List<dynamic> _filteredStudents(dynamic students) {
    final query =
        _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return List<dynamic>.from(students);
    }

    return List<dynamic>.from(students).where((student) {
      final name =
          (student['studentName'] ?? '')
              .toString()
              .toLowerCase();

      final number =
          (student['studentNumber'] ?? '')
              .toString()
              .toLowerCase();

      final email =
          (student['email'] ?? '')
              .toString()
              .toLowerCase();

      return name.contains(query) ||
          number.contains(query) ||
          email.contains(query);
    }).toList();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final studentsAsync = _studentsAsync;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subjectName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.className,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(
                teacherStudentsProvider(widget.classId),
              );
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        color: Colors.purple,
        onRefresh: () async {
          ref.invalidate(
            teacherStudentsProvider(widget.classId),
          );

          await ref.read(
            teacherStudentsProvider(widget.classId).future,
          );
        },
        child: studentsAsync.when(
          loading: () => ListView(
            physics: AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: 300,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.purple,
                  ),
                ),
              ),
            ],
          ),

          error: (error, stackTrace) {
            return _buildError(error);
          },

          data: (data) {
            /*
             * Your API appears to return:
             *
             * {
             *   "students": [...]
             * }
             *
             * But depending on your provider, it may already
             * return the students list.
             */

            final List<dynamic> students;

            if (data is Map<String, dynamic>) {
              students =
                  List<dynamic>.from(
                data['students'] ?? [],
              );
            } else if (data is List) {
              students =
                  List<dynamic>.from(data);
            } else {
              students = [];
            }

            return _buildBody(students);
          },
        ),
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(List<dynamic> students) {
    final filteredStudents =
        _filteredStudents(students);

    return Column(
      children: [
        // --------------------------------------------------------
        // HEADER
        // --------------------------------------------------------

        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            18,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.groups_outlined,
                      color: Colors.purple.shade700,
                      size: 27,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Students',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          '${students.length} student${students.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --------------------------------------------------
              // SEARCH
              // --------------------------------------------------

              TextField(
                controller: _searchController,
                onChanged: (_) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Search students...',
                  prefixIcon:
                      const Icon(Icons.search),

                  suffixIcon:
                      _searchController
                              .text
                              .isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                              ),
                              onPressed: () {
                                _searchController
                                    .clear();

                                setState(() {});
                              },
                            )
                          : null,

                  filled: true,
                  fillColor:
                      const Color(0xFFF7F7FB),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide:
                        BorderSide.none,
                  ),

                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color:
                          Colors.grey.shade200,
                    ),
                  ),

                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(
                      color: Colors.purple,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // --------------------------------------------------------
        // STUDENT LIST
        // --------------------------------------------------------

        Expanded(
          child: filteredStudents.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding:
                      const EdgeInsets.all(16),

                  physics:
                      const AlwaysScrollableScrollPhysics(),

                  itemCount:
                      filteredStudents.length,

                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),

                  itemBuilder:
                      (context, index) {
                    final student =
                        filteredStudents[index];

                    return _buildStudentCard(
                      student,
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ============================================================
  // STUDENT CARD
  // ============================================================

  Widget _buildStudentCard(dynamic student) {
    final name =
        student['studentName']
                ?.toString() ??
            'Unknown Student';

    final studentNumber =
        student['studentNumber']
                ?.toString() ??
            '';

    final email =
        student['email']
                ?.toString() ??
            '';

    final phoneNumber =
        student['phoneNumber']
                ?.toString() ??
            '';

    final initial = name.trim().isNotEmpty
        ? name.trim()[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Row(
        children: [
          // ------------------------------------------------------
          // AVATAR
          // ------------------------------------------------------

          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  color:
                      Colors.purple.shade700,
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(width: 13),

          // ------------------------------------------------------
          // DETAILS
          // ------------------------------------------------------

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                if (studentNumber.isNotEmpty) ...[
                  const SizedBox(height: 4),

                  Text(
                    studentNumber,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                ],

                if (email.isNotEmpty) ...[
                  const SizedBox(height: 3),

                  Text(
                    email,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey.shade500,
                    ),
                  ),
                ],

                if (phoneNumber.isNotEmpty) ...[
                  const SizedBox(height: 3),

                  Text(
                    phoneNumber,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ------------------------------------------------------
          // MORE
          // ------------------------------------------------------

          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'details') {
                context.push(
                  '/teacher/students/details',
                  extra: student,
                );
              }
            },

            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'details',
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                    ),
                    SizedBox(width: 10),
                    Text('View details'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final isSearching =
        _searchController.text
            .trim()
            .isNotEmpty;

    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height:
              MediaQuery.of(context).size.height *
                  0.5,
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    isSearching
                        ? Icons.search_off
                        : Icons.groups_outlined,
                    size: 60,
                    color:
                        Colors.grey.shade400,
                  ),

                  const SizedBox(height: 16),

                  Text(
                    isSearching
                        ? 'No students found'
                        : 'No students found in this class',
                    textAlign:
                        TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(
                    isSearching
                        ? 'Try searching with another name or student number.'
                        : 'There are currently no students assigned to this class.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(Object error) {
    return ListView(
      physics:
          const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height:
              MediaQuery.of(context).size.height *
                  0.7,
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color:
                        Colors.red.shade300,
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Unable to load students',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    error
                        .toString()
                        .replaceFirst(
                          'Exception: ',
                          '',
                        ),
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(
                        teacherStudentsProvider(
                          widget.classId,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.refresh,
                    ),
                    label:
                        const Text('Try again'),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.purple,
                      foregroundColor:
                          Colors.white,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
