import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CurrencyItem extends StatelessWidget {
  final String label;
  final String buy;
  final String sell;
  const CurrencyItem({super.key, required this.label, required this.buy, required this.sell});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(children: [
          Text("شراء: $buy", style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text("بيع: $sell", style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
        ])
      ],
    );
  }
}

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
      highlightColor: isDark ? const Color(0xFF1F2937) : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 8),
          Container(height: 12, width: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
        ],
      ),
    );
  }
}
