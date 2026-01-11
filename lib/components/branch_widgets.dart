import 'package:flutter/material.dart';
import 'package:libyan_banking_hub/models/models.dart';
import 'package:libyan_banking_hub/theme/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart' as intl;

class StatusBadge extends StatelessWidget {
  final LiquidityStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status.backgroundColor(isDark),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: status.color(isDark), fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class BranchCard extends StatelessWidget {
  final Branch branch;
  final Function(Branch) onReport;

  const BranchCard({super.key, required this.branch, required this.onReport});

  Future<void> _openMap(double lat, double lng) async {
    final Uri googleMapsUrl =
        Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.gray800 : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDarkMode ? AppColors.gray700 : AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDarkMode ? 50 : 10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(branch.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          if (branch.isAtm)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.blue.withAlpha(30),
                                  borderRadius: BorderRadius.circular(6)),
                              child: const Text("ATM",
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(branch.address,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _openMap(branch.lat, branch.lng),
                  icon: const Icon(Icons.directions, color: Colors.blue),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? AppColors.white.withAlpha(10)
                  : AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text("الحالة:",
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(width: 8),
                    StatusBadge(status: branch.status),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      "تحديث: ${intl.DateFormat('HH:mm').format(branch.lastUpdate)}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () => onReport(branch),
              icon: const Icon(Icons.add_chart_outlined, size: 20),
              label: const Text("إبلاغ عن الحالة",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showReportDialog(BuildContext context, Branch branch,
    Function(String, LiquidityStatus) onSubmit) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("تحديث حالة: ${branch.name}",
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildStatusButton(
              ctx, LiquidityStatus.available, branch.id, onSubmit),
          const SizedBox(height: 10),
          _buildStatusButton(
              ctx, LiquidityStatus.crowded, branch.id, onSubmit),
          const SizedBox(height: 10),
          _buildStatusButton(
              ctx, LiquidityStatus.empty, branch.id, onSubmit),
        ],
      ),
    ),
  );
}

Widget _buildStatusButton(BuildContext context, LiquidityStatus status, String id, Function onSubmit) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return InkWell(
    onTap: () {
      onSubmit(id, status);
      Navigator.pop(context);
    },
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: status.backgroundColor(isDark),
          border: Border.all(color: status.color(isDark)),
          borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.circle, color: status.color(isDark), size: 14),
        const SizedBox(width: 10),
        Text(status.label, style: TextStyle(color: status.color(isDark), fontWeight: FontWeight.bold)),
      ]),
    ),
  );
}
