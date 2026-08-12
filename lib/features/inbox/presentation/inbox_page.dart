import 'package:flutter/material.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  String selectedFilter = 'All';
  final TextEditingController searchController = TextEditingController();

  final List<Map<String, dynamic>> messages = [
    {
      'sender': 'Mr. Anderson',
      'role': 'Mathematics Teacher',
      'subject': 'Mathematics Assignment',
      'message':
          'Please remember to complete the Algebra assignment before Friday.',
      'time': '10:30 AM',
      'date': 'Today',
      'isRead': false,
      'color': const Color(0xFF091993),
      'icon': Icons.calculate_outlined,
    },
    {
      'sender': 'School Administration',
      'role': 'Administration',
      'subject': 'School Fees Reminder',
      'message':
          'This is a reminder that the deadline for payment of school fees is approaching.',
      'time': 'Yesterday',
      'date': 'Aug 10',
      'isRead': false,
      'color': Colors.orange,
      'icon': Icons.account_balance_outlined,
    },
    {
      'sender': 'Mrs. Williams',
      'role': 'English Teacher',
      'subject': 'Essay Submission',
      'message':
          'Your English essay has been received successfully. Well done!',
      'time': 'Yesterday',
      'date': 'Aug 10',
      'isRead': true,
      'color': Colors.green,
      'icon': Icons.menu_book_outlined,
    },
    {
      'sender': 'School Administration',
      'role': 'Administration',
      'subject': 'Parents Meeting',
      'message':
          'The next parents and teachers meeting will hold this Saturday.',
      'time': 'Aug 9',
      'date': 'Aug 9',
      'isRead': true,
      'color': Colors.purple,
      'icon': Icons.groups_outlined,
    },
    {
      'sender': 'Dr. Johnson',
      'role': 'Biology Teacher',
      'subject': 'Biology Practical',
      'message':
          'Please come prepared for tomorrow\'s practical class.',
      'time': 'Aug 8',
      'date': 'Aug 8',
      'isRead': true,
      'color': Colors.teal,
      'icon': Icons.biotech_outlined,
    },
  ];

  List<Map<String, dynamic>> get filteredMessages {
    List<Map<String, dynamic>> result = messages;

    if (selectedFilter == 'Unread') {
      result = result.where((message) => !message['isRead']).toList();
    }

    if (selectedFilter == 'Read') {
      result = result.where((message) => message['isRead']).toList();
    }

    final search = searchController.text.trim().toLowerCase();

    if (search.isNotEmpty) {
      result = result.where((message) {
        return message['sender'].toString().toLowerCase().contains(search) ||
            message['subject'].toString().toLowerCase().contains(search) ||
            message['message'].toString().toLowerCase().contains(search);
      }).toList();
    }

    return result;
  }

  int get unreadCount {
    return messages.where((message) => !message['isRead']).length;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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

              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackButton(),

                  const Text(
                    'Inbox',
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
                      Icons.edit_outlined,
                      size: 27,
                      color: Color(0xFF2F313D),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // SUMMARY CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF091993),
                  borderRadius: BorderRadius.circular(22),
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
                        Icons.mail_outline,
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
                            'Your Messages',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$unreadCount Unread Messages',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        setState(() {
                          for (final message in messages) {
                            message['isRead'] = true;
                          }
                        });
                      },
                      icon: const Icon(
                        Icons.done_all,
                        color: Colors.white,
                      ),
                      tooltip: 'Mark all as read',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // SEARCH
              TextField(
                controller: searchController,
                onChanged: (_) {
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Search messages...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // FILTERS
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterButton('All'),
                    _filterButton('Unread'),
                    _filterButton('Read'),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // MESSAGE COUNT
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F313D),
                    ),
                  ),
                  Text(
                    '${filteredMessages.length} Messages',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // MESSAGE LIST
              Expanded(
                child: filteredMessages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.mail_outline,
                              size: 50,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'No messages found',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredMessages.length,
                        itemBuilder: (context, index) {
                          return _messageCard(
                            filteredMessages[index],
                          );
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
    final bool isSelected = selectedFilter == filter;

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
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected
              ? Colors.white
              : const Color(0xFF2F313D),
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF091993)
              : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _messageCard(Map<String, dynamic> message) {
    final bool isRead = message['isRead'];
    final Color color = message['color'];

    return GestureDetector(
      onTap: () {
        setState(() {
          message['isRead'] = true;
        });

        // Later:
        // context.push('/inbox/${message['id']}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF0F2FF),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: isRead
                ? Colors.grey.shade200
                : const Color(0xFF091993).withOpacity(0.15),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SENDER ICON
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                message['icon'],
                color: color,
                size: 24,
              ),
            ),

            const SizedBox(width: 12),

            // MESSAGE CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message['sender'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isRead
                                ? FontWeight.w600
                                : FontWeight.bold,
                            color: const Color(0xFF2F313D),
                          ),
                        ),
                      ),

                      Text(
                        message['time'],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  Text(
                    message['role'],
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    message['subject'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isRead
                          ? FontWeight.w500
                          : FontWeight.bold,
                      color: const Color(0xFF2F313D),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    message['message'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            if (!isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 5),
                decoration: const BoxDecoration(
                  color: Color(0xFF091993),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}