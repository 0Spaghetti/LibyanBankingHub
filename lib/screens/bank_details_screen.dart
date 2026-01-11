import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../components/branch_widgets.dart';
import '../components/liquidity_chart.dart';
import '../components/common_widgets.dart';

class BankDetailsScreen extends ConsumerWidget {
  final Bank bank;
  const BankDetailsScreen({super.key, required this.bank});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(branchesProvider);
    final aiAnalysis = ref.watch(aiAnalysisProvider);
    final bankBranches = branches.where((b) => b.bankId == bank.id).toList();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(bank.name, style: const TextStyle(fontWeight: FontWeight.bold))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text("توجه السيولة (آخر 7 أيام)", textAlign: TextAlign.start, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          const LiquidityChart(),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFF3F4F6)),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(isDarkMode ? 0 : 5), blurRadius: 10)]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.auto_awesome_rounded, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text("تحليل الذكاء الاصطناعي", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                ]),
                const SizedBox(height: 12),
                aiAnalysis.when(
                  data: (text) => Text(text ?? "اضغط للتحليل للحصول على ملخص ذكي لحالة السيولة.", textAlign: TextAlign.start, style: const TextStyle(height: 1.5)),
                  loading: () => const ShimmerLoading(),
                  error: (err, stack) => const Text("حدث خطأ في التحليل", textAlign: TextAlign.start),
                ),
                if (!aiAnalysis.isLoading && aiAnalysis.value == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ElevatedButton(
                      onPressed: () => ref.read(aiAnalysisProvider.notifier).runAnalysis(), 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("تحليل السيولة الآن", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text("الفروع", textAlign: TextAlign.start, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...bankBranches.map((branch) => BranchCard(
                branch: branch,
                onReport: (b) => showReportDialog(context, b, (id, status) {
                  ref.read(branchesProvider.notifier).updateBranchStatus(id, status);
                  ref.read(reportCountProvider.notifier).increment();
                }),
              ))
        ],
      ),
    );
  }
}
