import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:libyan_banking_hub/models/models.dart';

// 1. شاشة الترحيب (Splash)
class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), widget.onComplete);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[700],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            const Text("دليلي المصرفي",
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 10),
            const Text("رفيقك المالي في ليبيا",
                style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

// 1.5 شاشة التعريف (Onboarding)
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "title": "مرحباً بك في دليلي المصرفي",
      "desc": "تطبيقك الأول لمتابعة توفر السيولة والخدمات المصرفية في ليبيا.",
      "icon": "🏦"
    },
    {
      "title": "راقب السيولة لحظة بلحظة",
      "desc": "تعرف على حالة الزحام وتوفر السيولة في فروع المصارف قبل الذهاب إليها.",
      "icon": "💸"
    },
    {
      "title": "ذكاء اصطناعي لمساعدتك",
      "desc": "استخدم تقنيات الذكاء الاصطناعي للحصول على أفضل التوصيات المصرفية.",
      "icon": "🤖"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: _pages.length,
            itemBuilder: (ctx, idx) => Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_pages[idx]['icon']!, style: const TextStyle(fontSize: 80)),
                  const SizedBox(height: 40),
                  Text(_pages[idx]['title']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Text(_pages[idx]['desc']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                    onPressed: widget.onFinish, child: const Text("تخطي")),
                Row(
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.only(right: 5),
                      height: 10,
                      width: _currentPage == index ? 20 : 10,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.green
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      widget.onFinish();
                    } else {
                      _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text(_currentPage == _pages.length - 1 ? "ابدأ" : "التالي", style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// 2. شاشة الدخول (Auth)
class AuthScreen extends StatelessWidget {
  final VoidCallback onLogin;
  const AuthScreen({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.green),
            const SizedBox(height: 40),
            TextField(
                decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 16),
            TextField(
                obscureText: true,
                decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onLogin,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50)),
              child: const Text("دخول", style: TextStyle(color: Colors.white)),
            ),
            TextButton(onPressed: onLogin, child: const Text("تصفح كزائر")),
          ],
        ),
      ),
    );
  }
}

// 3. شاشة إضافة البيانات (Add Data) - المحسنة
class AddDataScreen extends StatefulWidget {
  final List<Bank> banks;
  final Function(Bank) onAddBank;
  final Function(Branch) onAddBranch;
  final VoidCallback onCancel;

  const AddDataScreen(
      {super.key,
      required this.banks,
      required this.onAddBank,
      required this.onAddBranch,
      required this.onCancel});

  @override
  State<AddDataScreen> createState() => _AddDataScreenState();
}

class _AddDataScreenState extends State<AddDataScreen>
    with SingleTickerProviderStateMixin {
  // Tab State
  String _activeTab = 'BANK'; // 'BANK' or 'BRANCH'

  // Bank Form Controllers
  final _bankNameController = TextEditingController();
  final _bankCityController = TextEditingController();
  final _bankFormKey = GlobalKey<FormState>();

  // Branch Form Controllers
  final _branchNameController = TextEditingController();
  final _branchAddressController = TextEditingController();
  final _branchFormKey = GlobalKey<FormState>();
  
  String? _selectedBankId;
  bool _isAtm = false;

  @override
  void initState() {
    super.initState();
    if (widget.banks.isNotEmpty) {
      _selectedBankId = widget.banks[0].id;
    }
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _bankCityController.dispose();
    _branchNameController.dispose();
    _branchAddressController.dispose();
    super.dispose();
  }

  // --- Handlers ---

  void _handleBankSubmit() {
    if (_bankFormKey.currentState!.validate()) {
      final name = _bankNameController.text;
      
      final newBank = Bank(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        city: _bankCityController.text,
        logoUrl: "https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random&color=fff",
      );

      widget.onAddBank(newBank);

      // Reset
      _bankNameController.clear();
      _bankCityController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة المصرف بنجاح')));
    }
  }

  void _handleBranchSubmit() {
    if (_branchFormKey.currentState!.validate() && _selectedBankId != null) {
      final random = Random();
      
      final newBranch = Branch(
        id: "new-${DateTime.now().millisecondsSinceEpoch}",
        bankId: _selectedBankId!,
        name: _branchNameController.text,
        address: _branchAddressController.text.isNotEmpty 
            ? _branchAddressController.text 
            : _bankCityController.text, // Fallback
        // Simulate random coordinates around Tripoli
        lat: 32.88 + (random.nextDouble() * 0.1),
        lng: 13.19 + (random.nextDouble() * 0.1),
        isAtm: _isAtm,
        status: LiquidityStatus.unknown,
        lastUpdate: DateTime.now(),
        crowdLevel: 0,
      );

      widget.onAddBranch(newBranch);

      // Reset
      _branchNameController.clear();
      _branchAddressController.clear();
      setState(() => _isAtm = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إضافة الفرع بنجاح')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text("إضافة بيانات جديدة"),
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: widget.onCancel),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Tabs ---
                Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[100]!)),
                  ),
                  child: Row(
                    children: [
                      _buildTab('BANK', 'إضافة مصرف', primaryColor, isDark),
                      _buildTab('BRANCH', 'إضافة فرع', primaryColor, isDark),
                    ],
                  ),
                ),

                // --- Form Content ---
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _activeTab == 'BANK' 
                    ? _buildBankForm(isDark, primaryColor) 
                    : _buildBranchForm(isDark, primaryColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildTab(String id, String label, Color primaryColor, bool isDark) {
    final isActive = _activeTab == id;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isActive 
              ? (isDark ? primaryColor.withOpacity(0.2) : const Color(0xFFEFF6FF))
              : null,
            border: isActive 
              ? Border(bottom: BorderSide(color: primaryColor, width: 2)) 
              : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isActive 
                ? primaryColor 
                : (isDark ? Colors.grey[400] : Colors.grey[500]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankForm(bool isDark, Color primaryColor) {
    return Form(
      key: _bankFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabel("اسم المصرف", isDark),
          _buildInput(_bankNameController, "مثال: مصرف الجمهورية", isDark),
          const SizedBox(height: 16),
          
          _buildLabel("المدينة الرئيسية", isDark),
          _buildInput(_bankCityController, "مثال: طرابلس", isDark),
          const SizedBox(height: 24),
          
          _buildSubmitButton("حفظ المصرف", _handleBankSubmit, primaryColor),
        ],
      ),
    );
  }

  Widget _buildBranchForm(bool isDark, Color primaryColor) {
    return Form(
      key: _branchFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabel("اختر المصرف", isDark),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111827) : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? Colors.grey[600]! : Colors.grey[200]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: _selectedBankId,
                decoration: const InputDecoration(border: InputBorder.none),
                dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                items: widget.banks.map((bank) {
                  return DropdownMenuItem(
                    value: bank.id,
                    child: Text(bank.name, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedBankId = val),
              ),
            ),
          ),
          const SizedBox(height: 16),

          _buildLabel("اسم الفرع", isDark),
          _buildInput(_branchNameController, "مثال: فرع ذات العماد", isDark),
          const SizedBox(height: 16),

          _buildLabel("العنوان", isDark),
          _buildInput(_branchAddressController, "مثال: طريق الشط", isDark, isRequired: false),
          const SizedBox(height: 16),

          // Checkbox
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: _isAtm,
                  activeColor: primaryColor,
                  onChanged: (val) => setState(() => _isAtm = val ?? false),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "يحتوي على صراف آلي (ATM)",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Info Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.2) : const Color(0xFFEFF6FF), // blue-50
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE), // blue-100
              ),
            ),
            child: Text(
              "ملاحظة: سيتم تحديد موقع الفرع تلقائياً بشكل تقريبي على الخريطة في هذه النسخة التجريبية.",
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildSubmitButton("حفظ الفرع", _handleBranchSubmit, primaryColor),
        ],
      ),
    );
  }

  // --- Input Helpers ---

  Widget _buildLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.grey[300] : Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, bool isDark, {bool isRequired = true}) {
    return TextFormField(
      controller: controller,
      textAlign: TextAlign.start,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      validator: isRequired ? (value) {
        if (value == null || value.isEmpty) return 'هذا الحقل مطلوب';
        return null;
      } : null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
        filled: true,
        fillColor: isDark ? const Color(0xFF111827) : Colors.grey[50],
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: isDark ? Colors.grey[600]! : Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(String text, VoidCallback onPressed, Color primaryColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.3),
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
