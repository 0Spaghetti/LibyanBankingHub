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
  late TabController _tabController;
  final _bankFormKey = GlobalKey<FormState>();
  final _branchFormKey = GlobalKey<FormState>();
  
  final _bankNameController = TextEditingController();
  final _bankCityController = TextEditingController(text: "طرابلس");
  
  final _branchNameController = TextEditingController();
  final _branchAddressController = TextEditingController();
  String? _selectedBankId;

  // Location State
  LatLng _selectedLocation = const LatLng(32.8872, 13.1913);
  bool _isGettingLocation = false;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    if (widget.banks.isNotEmpty) _selectedBankId = widget.banks.first.id;
    super.initState();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() => _isGettingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("إضافة بيانات جديدة"),
        leading: IconButton(
            icon: const Icon(Icons.close), onPressed: widget.onCancel),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance), text: "إضافة مصرف"),
            Tab(icon: Icon(Icons.store), text: "إضافة فرع"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Form 1: Bank
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _bankFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("معلومات المصرف", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _bankNameController,
                    decoration: InputDecoration(
                      labelText: "اسم المصرف",
                      prefixIcon: const Icon(Icons.business),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v!.isEmpty ? "يرجى إدخال الاسم" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _bankCityController,
                    decoration: InputDecoration(
                      labelText: "المدينة الرئيسية",
                      prefixIcon: const Icon(Icons.location_city),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      if (_bankFormKey.currentState!.validate()) {
                        HapticFeedback.mediumImpact();
                        widget.onAddBank(Bank(
                            id: DateTime.now().toString(),
                            name: _bankNameController.text,
                            city: _bankCityController.text,
                            logoUrl: "https://picsum.photos/seed/${_bankNameController.text}/200"));
                        _bankNameController.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("حفظ بيانات المصرف", style: TextStyle(color: Colors.white, fontSize: 16)),
                  )
                ],
              ),
            ),
          ),
          // Form 2: Branch
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _branchFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("معلومات الفرع", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedBankId,
                    decoration: InputDecoration(
                      labelText: "اختر المصرف التابع له",
                      prefixIcon: const Icon(Icons.account_balance),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: widget.banks
                        .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedBankId = v),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _branchNameController,
                    decoration: InputDecoration(
                      labelText: "اسم الفرع أو موقع الصراف",
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v!.isEmpty ? "يرجى إدخال اسم الفرع" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _branchAddressController,
                    decoration: InputDecoration(
                      labelText: "العنوان التفصيلي",
                      prefixIcon: const Icon(Icons.map_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v!.isEmpty ? "يرجى إدخال العنوان" : null,
                  ),
                  const SizedBox(height: 24),
                  const Text("موقع الفرع على الخريطة", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: _selectedLocation,
                              initialZoom: 14.0,
                              onTap: (tapPosition, point) => setState(() => _selectedLocation = point),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.libyan_banking_hub',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _selectedLocation,
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: FloatingActionButton.small(
                              onPressed: _getCurrentLocation,
                              backgroundColor: Colors.white,
                              child: _isGettingLocation 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.my_location, color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text("اضغط على الخريطة لتحديد الموقع بدقة", style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      if (_branchFormKey.currentState!.validate()) {
                        HapticFeedback.mediumImpact();
                        widget.onAddBranch(Branch(
                            id: "new-${DateTime.now()}",
                            bankId: _selectedBankId!,
                            name: _branchNameController.text,
                            address: _branchAddressController.text,
                            lat: _selectedLocation.latitude,
                            lng: _selectedLocation.longitude,
                            isAtm: _branchNameController.text.toLowerCase().contains("atm") || _branchNameController.text.contains("صراف"),
                            status: LiquidityStatus.unknown,
                            lastUpdate: DateTime.now(),
                            crowdLevel: 0));
                        _branchNameController.clear();
                        _branchAddressController.clear();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("إضافة الفرع الآن", style: TextStyle(color: Colors.white, fontSize: 16)),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
