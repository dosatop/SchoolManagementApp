import 'package:flutter/material.dart';
import 'package:app/core/Models/info_card_model.dart';

class InfoCard extends StatelessWidget {
  final InfoCardModel infoCardModel;

  const InfoCard({super.key, required this.infoCardModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: infoCardModel.isSingleTitle
          ? _singleInfo()
          : Row(
              children: [
                Expanded(
                  child: _infoItem(
                    title: infoCardModel.title1,
                    value: infoCardModel.subtitle1,
                  ),
                ),

                Container(width: 1, height: 45, color: Colors.grey.shade200),

                const SizedBox(width: 16),

                Expanded(
                  child: _infoItem(
                    title: infoCardModel.title2 ?? '',
                    value: infoCardModel.subtitle2 ?? '',
                  ),
                ),
              ],
            ),
    );
  }

  Widget _singleInfo() {
    return _infoItem(
      title: infoCardModel.title1,
      value: infoCardModel.subtitle1,
    );
  }

  Widget _infoItem({required String title, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF091993),
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width: 7),

            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 7),

        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF2F313D),
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
