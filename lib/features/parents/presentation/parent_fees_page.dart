import 'package:flutter/material.dart';

class ParentFeesPage extends StatelessWidget {
  const ParentFeesPage({super.key});

  static const Color primary = Color(0xFF091993);
  static const Color background = Color(0xFFF7F7F7);
  static const Color textDark = Color(0xFF2F313D);

  @override
  Widget build(BuildContext context) {
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
          'School Fees',
          style: TextStyle(
            color: textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),

        padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),

        children: [
          _summaryCard(),

          const SizedBox(height: 28),

          const Text(
            'Children Fees',
            style: TextStyle(
              color: textDark,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'View your children\'s fee information',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 14),

          _childFeeCard(
            name: 'John Doe',
            className: 'Year 9',
            studentNumber: 'STU-001',
            total: '₦250,000',
            paid: '₦200,000',
            outstanding: '₦50,000',
            status: 'Partially Paid',
            statusColor: Colors.orange,
          ),

          _childFeeCard(
            name: 'Jane Doe',
            className: 'Year 6',
            studentNumber: 'STU-002',
            total: '₦200,000',
            paid: '₦200,000',
            outstanding: '₦0',
            status: 'Fully Paid',
            statusColor: Colors.green,
          ),

          const SizedBox(height: 28),

          const Text(
            'Fee Breakdown',
            style: TextStyle(
              color: textDark,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          _feeItem(
            icon: Icons.school_outlined,
            title: 'Tuition Fees',
            subtitle: '2025/2026 Academic Session',
            amount: '₦300,000',
            color: primary,
          ),

          _feeItem(
            icon: Icons.directions_bus_outlined,
            title: 'Transportation',
            subtitle: 'School bus service',
            amount: '₦80,000',
            color: Colors.orange,
          ),

          _feeItem(
            icon: Icons.restaurant_outlined,
            title: 'School Feeding',
            subtitle: 'Term feeding charges',
            amount: '₦50,000',
            color: Colors.green,
          ),

          _feeItem(
            icon: Icons.menu_book_outlined,
            title: 'Books & Materials',
            subtitle: 'Academic materials',
            amount: '₦20,000',
            color: Colors.purple,
          ),

          const SizedBox(height: 28),

          _paymentNotice(),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            primary,
            Color(0xFF1729B8),
          ],
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

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,

                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.payments_outlined,
                  color: Colors.white,
                  size: 27,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Outstanding Fees',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      '₦50,000',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            height: 1,
            color: Colors.white.withOpacity(.15),
          ),

          const SizedBox(height: 14),

          const Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  title: 'Total Fees',
                  value: '₦450,000',
                ),
              ),

              Expanded(
                child: _SummaryItem(
                  title: 'Paid',
                  value: '₦400,000',
                ),
              ),

              Expanded(
                child: _SummaryItem(
                  title: 'Balance',
                  value: '₦50,000',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _childFeeCard({
    required String name,
    required String className,
    required String studentNumber,
    required String total,
    required String paid,
    required String outstanding,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: primary.withOpacity(.08),
                  borderRadius: BorderRadius.circular(13),
                ),

                child: const Icon(
                  Icons.person_outline_rounded,
                  color: primary,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '$className • $studentNumber',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.09),
                  borderRadius: BorderRadius.circular(9),
                ),

                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _feeStat(
                  'Total',
                  total,
                  primary,
                ),
              ),

              Expanded(
                child: _feeStat(
                  'Paid',
                  paid,
                  Colors.green,
                ),
              ),

              Expanded(
                child: _feeStat(
                  'Balance',
                  outstanding,
                  outstanding == '₦0'
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _feeStat(
    String title,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _feeItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,

            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(
              icon,
              color: color,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          Text(
            amount,
            style: const TextStyle(
              color: textDark,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentNotice() {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(.07),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.orange.withOpacity(.2),
        ),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Colors.orange,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              'Please contact the school accounts office for payment details and official payment instructions.',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryItem({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}