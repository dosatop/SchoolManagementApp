import 'package:app/core/Widgets/Cards/assingment_card.dart';
import 'package:app/features/assignment/models/assignment_model.dart';
import 'package:flutter/material.dart';

class AssignmentPage extends StatefulWidget {
  const AssignmentPage({super.key});

  @override
  State<AssignmentPage> createState() => _AssignmentPageState();
}

class _AssignmentPageState extends State<AssignmentPage> {
  String selectedFilter = 'All';

  final List<Assignment> assignments = [
    Assignment(
      id: '1',
      subject: 'Mathematics',
      title: 'Algebra Assignment',
      description: 'Solve questions 1 - 20 from chapter 5.',
      dueDate: 'Aug 14, 2026',
      status: 'Pending',
      color: Colors.orange,
    ),
    Assignment(
      id: '2',
      subject: 'English',
      title: 'Essay Writing',
      description: 'Write an essay about the importance of education.',
      dueDate: 'Aug 16, 2026',
      status: 'Submitted',
      color: Colors.green,
    ),
    Assignment(
      id: '3',
      subject: 'Biology',
      title: 'Human Digestive System',
      description: 'Draw and label the human digestive system.',
      dueDate: 'Aug 10, 2026',
      status: 'Overdue',
      color: Colors.red,
    ),
    Assignment(
      id: '4',
      subject: 'Physics',
      title: 'Motion and Forces',
      description: 'Complete the questions on motion and forces.',
      dueDate: 'Aug 20, 2026',
      status: 'Pending',
      color: Colors.orange,
    ),
  ];

  List<Assignment> get filteredAssignments {
    if (selectedFilter == 'All') {
      return assignments;
    }

    return assignments
        .where((assignment) => assignment.status == selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackButton(),

                  const Text(
                    'Assignments',
                    style: TextStyle(
                      fontSize: 24,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F313D),
                    ),
                  ),

                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_outlined,
                      size: 30,
                      color: Color(0xFF2F313D),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF091993),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.assignment_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),

                    const SizedBox(width: 15),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Assignments',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            '${assignments.length} Assignments',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Filters
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterButton('All'),
                    _filterButton('Pending'),
                    _filterButton('Submitted'),
                    _filterButton('Overdue'),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // Assignment list
              Expanded(
                child: filteredAssignments.isEmpty
                    ? const Center(
                        child: Text(
                          'No assignments found',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredAssignments.length,
                        itemBuilder: (context, index) {
                          final assignment = filteredAssignments[index];

                          return AssignmentCard(assignment: assignment);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterButton(String filter) {
    final isSelected = selectedFilter == filter;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(filter),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            selectedFilter = filter;
          });
        },
        selectedColor: const Color(0xFF091993),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFF091993) : Colors.grey.shade300,
        ),
      ),
    );
  }
}
