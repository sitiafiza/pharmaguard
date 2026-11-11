import 'package:flutter/material.dart';
import '../../../domain/models/enums.dart';
import '../app_colors.dart';

class UrgencyBadge extends StatelessWidget {
  final ExpiryUrgency urgency;
  final String text;
  final bool isQuarantined;

  const UrgencyBadge({
    super.key,
    required this.urgency,
    required this.text,
    this.isQuarantined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isQuarantined) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: const Text(
          'Karantina',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
      );
    }

    Color bgColor;
    Color textColor;

    switch (urgency) {
      case ExpiryUrgency.critical:
        bgColor = AppColors.coralRedContainer;
        textColor = AppColors.coralRedDark;
        break;
      case ExpiryUrgency.warning:
      case ExpiryUrgency.attention:
        bgColor = AppColors.warningYellowContainer;
        textColor = AppColors.warningYellowDark;
        break;
      case ExpiryUrgency.safe:
        bgColor = AppColors.safeGreenContainer;
        textColor = AppColors.safeGreenDark;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
