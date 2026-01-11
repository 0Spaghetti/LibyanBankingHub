import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  final VoidCallback onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportCount = ref.watch(reportCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF10B981), width: 2)),
                child: CircleAvatar(radius: 50, backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.grey[200], child: const Icon(Icons.person_rounded, size: 50, color: Colors.grey)),
              ),
              const SizedBox(height: 16),
              const Text("المستخدم التجريبي", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text("user@example.com", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _buildProfileItem(Icons.analytics_rounded, "عدد البلاغات", reportCount.toString(), isDark),
        _buildProfileItem(Icons.settings_rounded, "إعدادات الحساب", null, isDark),
        _buildProfileItem(Icons.info_rounded, "حول التطبيق", "v1.0.0", isDark),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.withAlpha(20), 
            foregroundColor: Colors.red,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.red, width: 0.5)),
            minimumSize: const Size(double.infinity, 55),
          ),
          child: const Text("تسجيل الخروج", style: TextStyle(fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String? trailing, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF10B981)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: trailing != null ? Text(trailing, style: const TextStyle(fontWeight: FontWeight.bold)) : const Icon(Icons.chevron_left_rounded),
      ),
    );
  }
}
