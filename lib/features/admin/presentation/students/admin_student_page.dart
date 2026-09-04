import 'package:app/features/admin/models/students/admin_student_model.dart';
import 'package:app/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminStudentsPage extends ConsumerStatefulWidget {
  final String schoolId;
  final String? schoolName;

  const AdminStudentsPage({super.key, required this.schoolId, this.schoolName});

  @override
  ConsumerState<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends ConsumerState<AdminStudentsPage> {
  static const Color primary = Color(0xFF091993);
  static const Color primaryLight = Color(0xFFE9ECFF);
  static const Color background = Color(0xFFF6F7FB);
  static const Color textDark = Color(0xFF20232E);

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  // null = All Departments
  String? _selectedDepartmentId;

  // null = All Classes
  String? _selectedClassId;

  String get schoolId => widget.schoolId;

  String get schoolTitle {
    final name = widget.schoolName?.trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return 'My School';
  }

  // ================================================================
  // INIT
  // ================================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      final query = _searchController.text.trim().toLowerCase();

      if (_searchQuery == query) {
        return;
      }

      setState(() {
        _searchQuery = query;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================================================================
  // REFRESH
  // ================================================================

  Future<void> _refresh() async {
    await ref.read(adminDashboardProvider.notifier).refresh();
  }

  // ================================================================
  // DEPARTMENTS
  // ================================================================

  List<Map<String, String>> _departments(List<AdminStudentModel> students) {
    final Map<String, String> departmentMap = {};

    for (final student in students) {
      final departmentId = student.departmentId?.trim();
      final departmentName = student.departmentName?.trim();

      if (departmentId != null &&
          departmentId.isNotEmpty &&
          departmentName != null &&
          departmentName.isNotEmpty) {
        departmentMap[departmentId] = departmentName;
      }
    }

    final departments = departmentMap.entries
        .map((entry) => {'id': entry.key, 'name': entry.value})
        .toList();

    departments.sort(
      (a, b) => a['name']!.toLowerCase().compareTo(b['name']!.toLowerCase()),
    );

    return departments;
  }

  // ================================================================
  // CLASSES
  // ================================================================

  List<Map<String, String>> _classes(List<AdminStudentModel> students) {
    final Map<String, String> classMap = {};

    for (final student in students) {
      final classId = student.classId?.trim();
      final className = student.className?.trim();

      if (classId != null &&
          classId.isNotEmpty &&
          className != null &&
          className.isNotEmpty) {
        classMap[classId] = className;
      }
    }

    final classes = classMap.entries
        .map((entry) => {'id': entry.key, 'name': entry.value})
        .toList();

    classes.sort(
      (a, b) => a['name']!.toLowerCase().compareTo(b['name']!.toLowerCase()),
    );

    return classes;
  }

  // ================================================================
  // FILTER
  // ================================================================

  List<AdminStudentModel> _filteredStudents(List<AdminStudentModel> students) {
    return students.where((student) {
      final name = student.studentName.trim().toLowerCase();

      final number = student.studentNumber.trim().toLowerCase();

      final className = (student.className ?? '').trim().toLowerCase();

      final schoolLevel = student.schoolLevel.trim().toLowerCase();

      final departmentName = (student.departmentName ?? '')
          .trim()
          .toLowerCase();

      final tradeName = (student.tradeName ?? '').trim().toLowerCase();

      final matchesSearch =
          _searchQuery.isEmpty ||
          name.contains(_searchQuery) ||
          number.contains(_searchQuery) ||
          className.contains(_searchQuery) ||
          schoolLevel.contains(_searchQuery) ||
          departmentName.contains(_searchQuery) ||
          tradeName.contains(_searchQuery);

      final matchesDepartment =
          _selectedDepartmentId == null ||
          student.departmentId == _selectedDepartmentId;

      final matchesClass =
          _selectedClassId == null || student.classId == _selectedClassId;

      return matchesSearch && matchesDepartment && matchesClass;
    }).toList();
  }

  // ================================================================
  // PROFILE
  // ================================================================

  void _openStudentProfile(AdminStudentModel student) {
    context.push('/admin/$schoolId/student/${student.studentId}');
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminDashboardProvider);

    final allStudents = adminState.value?.students ?? [];

    final departments = _departments(allStudents);
    final classes = _classes(allStudents);

    // Reset invalid department after refresh.
    if (_selectedDepartmentId != null &&
        !departments.any(
          (department) => department['id'] == _selectedDepartmentId,
        )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _selectedDepartmentId = null;
        });
      });
    }

    // Reset invalid class after refresh.
    if (_selectedClassId != null &&
        !classes.any((classItem) => classItem['id'] == _selectedClassId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _selectedClassId = null;
        });
      });
    }

    final students = _filteredStudents(allStudents);

    return Scaffold(
      backgroundColor: background,

      // ============================================================
      // APP BAR
      // ============================================================
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Students',
          style: TextStyle(color: textDark, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: adminState.isLoading ? null : _refresh,
            icon: const Icon(Icons.refresh_rounded, color: textDark),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ============================================================
      // ADD STUDENT
      // ============================================================
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        onPressed: () {
          context
              .push('/admin/$schoolId/create-student', extra: schoolTitle)
              .then((_) {
                if (mounted) {
                  _refresh();
                }
              });
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Add Student',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ============================================================
      // BODY
      // ============================================================
      body: SafeArea(
        child: RefreshIndicator(
          color: primary,
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // ======================================================
              // HEADER
              // ======================================================
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SCHOOL NAME
                      Text(
                        schoolTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 5),

                      // TITLE
                      const Text(
                        'Manage Students',
                        style: TextStyle(
                          color: textDark,
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // DESCRIPTION
                      Text(
                        'View and manage students in your school.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // SEARCH
                      _searchBox(),

                      const SizedBox(height: 12),

                      // DEPARTMENT + CLASS
                      Row(
                        children: [
                          Expanded(
                            child: _filterCard(
                              icon: Icons.account_tree_outlined,
                              label: 'DEPARTMENT',
                              value: _selectedDepartmentName(departments),
                              active: _selectedDepartmentId != null,
                              onTap: () {
                                _showFilterSheet(
                                  title: 'Select Department',
                                  icon: Icons.account_tree_outlined,
                                  options: departments,
                                  selectedValue: _selectedDepartmentId,
                                  allLabel: 'All Departments',
                                  onSelected: (value) {
                                    setState(() {
                                      _selectedDepartmentId = value;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _filterCard(
                              icon: Icons.class_outlined,
                              label: 'CLASS',
                              value: _selectedClassName(classes),
                              active: _selectedClassId != null,
                              onTap: () {
                                _showFilterSheet(
                                  title: 'Select Class',
                                  icon: Icons.class_outlined,
                                  options: classes,
                                  selectedValue: _selectedClassId,
                                  allLabel: 'All Classes',
                                  onSelected: (value) {
                                    setState(() {
                                      _selectedClassId = value;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // COUNT
                      _studentCount(
                        total: allStudents.length,
                        visible: students.length,
                      ),
                    ],
                  ),
                ),
              ),

              // ======================================================
              // INITIAL LOADING
              // ======================================================
              if (adminState.isLoading && adminState.value == null)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: primary),
                  ),
                )
              // ======================================================
              // ERROR
              // ======================================================
              else if (adminState.hasError && adminState.value == null)
                SliverFillRemaining(hasScrollBody: false, child: _errorState())
              // ======================================================
              // EMPTY
              // ======================================================
              else if (students.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _emptyState(hasStudents: allStudents.isNotEmpty),
                )
              // ======================================================
              // STUDENTS
              // ======================================================
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final student = students[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _studentCard(student),
                      );
                    }, childCount: students.length),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SEARCH BOX
  // ================================================================

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search name, student number or class...',
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          borderSide: BorderSide(color: primary, width: 1.4),
        ),
      ),
    );
  }

  // ================================================================
  // FILTER CARD
  // ================================================================

  Widget _filterCard({
    required IconData icon,
    required String label,
    required String value,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? primaryLight : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? primary.withOpacity(.35) : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: active ? Colors.white : primaryLight,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: primary, size: 17),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.grey,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SELECTED DEPARTMENT NAME
  // ================================================================

  String _selectedDepartmentName(List<Map<String, String>> departments) {
    if (_selectedDepartmentId == null) {
      return 'All Departments';
    }

    for (final department in departments) {
      if (department['id'] == _selectedDepartmentId) {
        return department['name'] ?? 'Department';
      }
    }

    return 'All Departments';
  }

  // ================================================================
  // SELECTED CLASS NAME
  // ================================================================

  String _selectedClassName(List<Map<String, String>> classes) {
    if (_selectedClassId == null) {
      return 'All Classes';
    }

    for (final classItem in classes) {
      if (classItem['id'] == _selectedClassId) {
        return classItem['name'] ?? 'Class';
      }
    }

    return 'All Classes';
  }

  // ================================================================
  // FILTER BOTTOM SHEET
  // ================================================================

  Future<void> _showFilterSheet({
    required String title,
    required IconData icon,
    required List<Map<String, String>> options,
    required String? selectedValue,
    required String allLabel,
    required ValueChanged<String?> onSelected,
  }) async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 520),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),

                // HANDLE
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 18),

                // HEADER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: primary, size: 21),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: textDark,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                const Divider(height: 1),

                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                    children: [
                      _filterOption(
                        sheetContext: sheetContext,
                        label: allLabel,
                        value: null,
                        selected: selectedValue == null,
                      ),

                      ...options.map((option) {
                        return _filterOption(
                          sheetContext: sheetContext,
                          label: option['name'] ?? 'Unknown',
                          value: option['id'],
                          selected: selectedValue == option['id'],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    onSelected(selected);
  }

  // ================================================================
  // FILTER OPTION
  // ================================================================

  Widget _filterOption({
    required BuildContext sheetContext,
    required String label,
    required String? value,
    required bool selected,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: selected ? primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
      ),
      child: ListTile(
        onTap: () {
          Navigator.pop(sheetContext, value);
        },
        leading: Icon(
          selected ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: selected ? primary : Colors.grey.shade500,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? primary : textDark,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: selected
            ? const Icon(Icons.check_rounded, color: primary)
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
  }

  // ================================================================
  // COUNT
  // ================================================================

  Widget _studentCount({required int total, required int visible}) {
    final filtered =
        _searchQuery.isNotEmpty ||
        _selectedDepartmentId != null ||
        _selectedClassId != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primaryLight,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups_outlined, color: primary, size: 16),

          const SizedBox(width: 6),

          Text(
            filtered
                ? '$visible found'
                : '$total ${total == 1 ? 'student' : 'students'}',
            style: const TextStyle(
              color: primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // STUDENT CARD
  // ================================================================

  Widget _studentCard(AdminStudentModel student) {
    final departmentName = (student.departmentName ?? '').trim();

    final tradeName = (student.tradeName ?? '').trim();

    final parentCount = student.parentCount;

    final className = (student.className ?? '').trim();

    final schoolLevel = student.schoolLevel.trim();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            _openStudentProfile(student);
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AVATAR
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: primaryLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      _initials(student),
                      style: const TextStyle(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 13),

                // DETAILS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.studentName.trim().isEmpty
                            ? 'Unnamed student'
                            : student.studentName.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 7),

                      // STUDENT NUMBER
                      Row(
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 14,
                            color: primary,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Student No: '
                              '${student.studentNumber.trim().isEmpty ? 'N/A' : student.studentNumber.trim()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      // CLASS
                      Row(
                        children: [
                          Icon(
                            Icons.class_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              className.isEmpty ? 'No class' : className,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // SCHOOL LEVEL
                      if (schoolLevel.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                schoolLevel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // DEPARTMENT
                      if (departmentName.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(
                              Icons.account_tree_outlined,
                              size: 14,
                              color: primary,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                departmentName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // TRADE
                      if (tradeName.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              Icons.construction_outlined,
                              size: 14,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                tradeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 10),

                      // PARENTS
                      Row(
                        children: [
                          _smallInfo(
                            icon: Icons.family_restroom_outlined,
                            label:
                                '$parentCount '
                                '${parentCount == 1 ? 'parent' : 'parents'}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 5),

                // MENU
                PopupMenuButton<String>(
                  tooltip: 'Student options',
                  onSelected: (value) {
                    if (value == 'profile') {
                      _openStudentProfile(student);
                    }

                    if (value == 'edit') {
                      context
                          .push(
                            '/admin/$schoolId/edit-student/${student.studentId}',
                            extra: student,
                          )
                          .then((_) {
                            if (mounted) {
                              _refresh();
                            }
                          });
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, size: 20),
                          SizedBox(width: 10),
                          Text('View Profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // SMALL INFO
  // ================================================================

  Widget _smallInfo({required IconData icon, required String label}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // INITIALS
  // ================================================================

  String _initials(AdminStudentModel student) {
    final name = student.studentName.trim();

    if (name.isEmpty) {
      return 'S';
    }

    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  // ================================================================
  // EMPTY STATE
  // ================================================================

  Widget _emptyState({required bool hasStudents}) {
    final filtered =
        _searchQuery.isNotEmpty ||
        _selectedDepartmentId != null ||
        _selectedClassId != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.groups_outlined,
                color: primary,
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              filtered ? 'No students found' : 'No students yet',
              style: const TextStyle(
                color: textDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              filtered
                  ? 'Try another search or change your filters.'
                  : 'Start by adding a student to your school.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                height: 1.4,
              ),
            ),

            // ADD STUDENT
            if (!filtered && !hasStudents) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  context.push(
                    '/admin/$schoolId/create-student',
                    extra: schoolTitle,
                  );
                },
                style: FilledButton.styleFrom(backgroundColor: primary),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add Student'),
              ),
            ],

            // CLEAR FILTERS
            if (filtered) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedDepartmentId = null;
                    _selectedClassId = null;
                  });

                  _searchController.clear();
                },
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ================================================================
  // ERROR
  // ================================================================

  Widget _errorState() {
    final error = ref.read(adminDashboardProvider).error;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 50,
            ),

            const SizedBox(height: 15),

            const Text(
              'Unable to load students',
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 7),

            Text(
              error?.toString() ??
                  'Something went wrong while loading students.',
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 18),

            FilledButton(
              onPressed: _refresh,
              style: FilledButton.styleFrom(backgroundColor: primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
