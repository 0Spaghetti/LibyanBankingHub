import 'package:flutter/material.dart';
import 'package:libyan_banking_hub/models/models.dart';
import 'package:url_launcher/url_launcher.dart';
import 'status_badge.dart';

// كارت الفرع القابل للتوسيع
class BranchCard extends StatefulWidget {
  final Branch branch;
  final Function(Branch) onReport;

  const BranchCard({super.key, required this.branch, required this.onReport});

  @override
  State<BranchCard> createState() => _BranchCardState();
}

class _BranchCardState extends State<BranchCard> {
  bool _expanded = false;

  Future<void> _openMap(double lat, double lng) async {
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      throw 'Could not open the map.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expanded = !_expanded),
            title: Row(children: [
              Text(widget.branch.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (widget.branch.isAtm)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                  child: const Text("ATM", style: TextStyle(fontSize: 10, color: Colors.blue)),
                )
            ]),
            subtitle: Row(children: [
              const Icon(Icons.location_on, size: 14, color: Colors.grey),
              Text(widget.branch.address, style: const TextStyle(fontSize: 12)),
            ]),
            trailing: Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () => _openMap(widget.branch.lat, widget.branch.lng),
                icon: const Icon(Icons.directions),
                label: const Text("الحصول على الاتجاهات"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(status: widget.branch.status),
                ElevatedButton.icon(
                  onPressed: () => widget.onReport(widget.branch),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text("إبلاغ"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0, side: const BorderSide(color: Colors.grey)),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// نافذة الإبلاغ (Dialog)
void showReportDialog(BuildContext context, Branch branch, Function(String, LiquidityStatus) onSubmit) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("تحديث حالة: ${branch.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildStatusButton(ctx, "سيولة متوفرة", Colors.green, LiquidityStatus.available, branch.id, onSubmit),
          const SizedBox(height: 10),
          _buildStatusButton(ctx, "مزدحم جداً", Colors.orange, LiquidityStatus.crowded, branch.id, onSubmit),
          const SizedBox(height: 10),
          _buildStatusButton(ctx, "لا توجد سيولة", Colors.red, LiquidityStatus.empty, branch.id, onSubmit),
        ],
      ),
    ),
  );
}

Widget _buildStatusButton(BuildContext context, String text, Color color, LiquidityStatus status, String id, Function onSubmit) {
  return InkWell(
    onTap: () {
      onSubmit(id, status);
      Navigator.pop(context);
    },
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withAlpha((255 * 0.1).round()), border: Border.all(color: color), borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.circle, color: color, size: 14),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ]),
    ),
  );
}
