import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';

class AuthScreen extends StatelessWidget {
  final VoidCallback onLogin;
  const AuthScreen({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final textColor = isDark ? AppColors.white : AppColors.gray900;
    final subTextColor = isDark ? AppColors.gray400 : AppColors.gray500;
    final inputBg = isDark ? AppColors.gray800 : AppColors.white;
    final inputBorder = isDark ? AppColors.gray700 : AppColors.gray200;

    return Scaffold(
      backgroundColor: isDark ? AppColors.gray900 : AppColors.gray50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Logo Section
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_rounded,
                    size: 40,
                    color: AppColors.primary500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // 2. Title & Subtitle
              Text(
                "تسجيل الدخول",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "قم بتسجيل الدخول للإبلاغ عن حالة السيولة",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: subTextColor,
                ),
              ),
              const SizedBox(height: 48),

              // 3. Email Field
              _buildLabel("البريد الإلكتروني", textColor),
              _buildTextField(
                hint: "user@example.com",
                icon: Icons.email_outlined,
                isDark: isDark,
                bgColor: inputBg,
                borderColor: inputBorder,
                textColor: textColor,
              ),
              const SizedBox(height: 24),

              // 4. Password Field
              _buildLabel("كلمة المرور", textColor),
              _buildTextField(
                hint: "********",
                icon: Icons.lock_outline,
                isDark: isDark,
                isPassword: true,
                bgColor: inputBg,
                borderColor: inputBorder,
                textColor: textColor,
              ),
              const SizedBox(height: 32),

              // 5. Login Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary500.withAlpha(isDark ? 60 : 40),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onLogin();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "دخول",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 6. Divider
              Row(
                children: [
                  Expanded(child: Divider(color: inputBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "أو",
                      style: TextStyle(color: AppColors.gray500, fontSize: 14),
                    ),
                  ),
                  Expanded(child: Divider(color: inputBorder)),
                ],
              ),
              const SizedBox(height: 32),

              // 7. Guest Button
              ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onLogin();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.gray800 : AppColors.white,
                  foregroundColor: textColor,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: inputBorder),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "تصفح كزائر",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        obscureText: isPassword,
        textAlign: TextAlign.start,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.gray500),
          prefixIcon: Icon(icon, color: AppColors.gray500, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
