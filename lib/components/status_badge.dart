// lib/components/status_badge.dart
import 'package:flutter/material.dart';
import 'package:libyan_banking_hub/models/models.dart';

class StatusBadge extends StatelessWidget {
  final LiquidityStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // تحديد الألوان والنصوص بناءً على الحالة (مشابه لـ StatusBadge.tsx)
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case LiquidityStatus.available:
        color = Colors.green;
        label = "متوفرة";
        icon = Icons.check_circle;
        break;
      case LiquidityStatus.crowded:
        color = Colors.orange;
        label = "مزدحمة";
        icon = Icons.warning;
        break;
      case LiquidityStatus.empty:
        color = Colors.red;
        label = "لا توجد سيولة";
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        label = "غير معروف";
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).round()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
