import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/models.dart';
import 'screens/misc_screens.dart';
import 'components/branch_widgets.dart';
import 'components/branch_map.dart';
import 'components/liquidity_chart.dart';
import 'providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const LibyanBankingApp(),
    ),
  );
}

class LibyanBankingApp extends StatefulWidget {
  const LibyanBankingApp({super.key});
  @override
  State<LibyanBankingApp> createState() => _LibyanBankingAppState();
}

class _LibyanBankingAppState extends State<LibyanBankingApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() => _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دليلي المصرفي',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4CAF50),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020617), // Deep Midnight
        appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Color(0xFF020617),
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          surfaceTintColor: Colors.transparent,
          color: Color(0xFF0F172A), // Midnight Blue component
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.dark,
          surface: const Color(0xFF0F172A),
          onSurface: const Color(0xFFF1F5F9),
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF22C55E),
        ),
      ),
      locale: const Locale('ar'),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: MainController(toggleTheme: toggleTheme),
    );
  }
}

class MainController extends ConsumerStatefulWidget {
  final VoidCallback toggleTheme;
  const MainController({super.key, required this.toggleTheme});

  @override
  ConsumerState<MainController> createState() => _MainControllerState();
}

class _MainControllerState extends ConsumerState<MainController> {
  String _view = 'SPLASH'; // SPLASH, ONBOARDING, AUTH, HOME, MAP, ADD, EMERGENCY, PROFILE
  Bank? _selectedBank;

  String _searchTerm = '';
  String _homeTab = 'ALL'; // ALL, FAVORITES
  String _selectedCity = 'الكل';
  bool _showAvailableOnly = false;
  
  // Search state
  bool _isSearching = false;
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  final List<String> _cities = [
    'الكل',
    'طرابلس',
    'بنغازي',
    'مصراتة',
    'الزاوية',
    'سبها'
  ];

  final List<Map<String, String>> _emergencyContacts = [
    {"name": "مصرف الجمهورية - طوارئ", "number": "1515"},
    {"name": "مصرف الوحدة - خدمات الزبائن", "number": "1100"},
    {"name": "مصرف الصحارى - بلاغات فقدان", "number": "1234"},
    {"name": "مركز البطاقات المصرفية", "number": "8888"},
  ];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    setState(() {
      _isSearching = true;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchTerm = query;
        _isSearching = false;
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final reportCount = ref.watch(reportCountProvider);

    if (_view == 'SPLASH') {
      return SplashScreen(
          onComplete: () => setState(() => _view = 'ONBOARDING'));
    }

    if (_view == 'ONBOARDING') {
      return OnboardingScreen(onFinish: () => setState(() => _view = 'AUTH'));
    }

    if (_view == 'AUTH') {
      return AuthScreen(onLogin: () => setState(() => _view = 'HOME'));
    }

    if (_view == 'ADD') {
      return AddDataScreen(
        banks: ref.watch(banksProvider),
        onCancel: () => setState(() => _view = 'HOME'),
        onAddBank: (b) {
          ref.read(banksProvider.notifier).addBank(b);
          setState(() => _view = 'HOME');
          _showToast("تمت إضافة المصرف");
        },
        onAddBranch: (b) {
          ref.read(branchesProvider.notifier).addBranch(b);
          setState(() => _view = 'HOME');
          _showToast("تمت إضافة الفرع");
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "دليلي المصرفي",
          style: TextStyle(
            color: Color(0xFF4CAF50),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF1E293B) // Slate blue
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Theme.of(context).brightness == Brightness.dark
                    ? Icons.wb_sunny_outlined
                    : Icons.dark_mode_outlined, size: 20),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.toggleTheme();
                },
              ),
            ),
          ),
        ],
        centerTitle: false,
      ),
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 400),
        reverse: _view == 'HOME',
        transitionBuilder: (child, animation, secondaryAnimation) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.scaled,
            child: FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.05),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
          );
        },
        child: _buildBody(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10, offset: const Offset(0, -5))
          ],
        ),
        child: NavigationBar(
          height: 80,
          elevation: 0,
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF0F172A) 
              : Colors.white,
          selectedIndex:
              _view == 'MAP' ? 1 : _view == 'ADD' ? 2 : _view == 'EMERGENCY' ? 3 : _view == 'PROFILE' ? 4 : 0,
          onDestinationSelected: (idx) {
            HapticFeedback.selectionClick();
            setState(() {
              if (idx == 0) _view = 'HOME';
              if (idx == 1) _view = 'MAP';
              if (idx == 2) _view = 'ADD';
              if (idx == 3) _view = 'EMERGENCY';
              if (idx == 4) _view = 'PROFILE';
            });
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: Colors.green), label: "الرئيسية"),
            NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map, color: Colors.green), label: "الخريطة"),
            NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle, color: Colors.green), label: "إضافة"),
            NavigationDestination(icon: Icon(Icons.phone_outlined), selectedIcon: Icon(Icons.phone, color: Colors.green), label: "طوارئ"),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: Colors.green), label: "حسابي"),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_view) {
      case 'MAP':
        final branches = ref.watch(branchesProvider);
        final banks = ref.watch(banksProvider);
        return BranchMap(
          branches: branches,
          onViewDetails: (branch) {
            final bank = banks.firstWhere((b) => b.id == branch.bankId);
            _selectedBank = bank;
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, _, __) => BankDetailsScreen(bank: bank),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SharedAxisTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.horizontal,
                    child: child,
                  );
                },
              ),
            );
          },
        );
      case 'EMERGENCY':
        return _buildEmergencyContacts();
      case 'PROFILE':
        return _buildProfile();
      case 'HOME':
      default:
        return _buildHome();
    }
  }

  Widget _buildHome() {
    final banks = ref.watch(banksProvider);
    final branches = ref.watch(branchesProvider);
    final favorites = ref.watch(favoritesProvider);

    final filteredBanks = banks.where((bank) {
      if (_homeTab == 'FAVORITES' && !favorites.contains(bank.id)) return false;
      
      bool matchesSearch = _searchTerm.isEmpty || bank.name.contains(_searchTerm);
      if (!matchesSearch && _searchTerm.isNotEmpty) {
        matchesSearch = branches.any((branch) => 
          branch.bankId == bank.id && (branch.address.contains(_searchTerm) || branch.name.contains(_searchTerm))
        );
      }
      
      if (!matchesSearch) return false;

      if (_selectedCity != 'الكل' && !bank.city.contains(_selectedCity))
        return false;

      if (_showAvailableOnly) {
        final hasLiquidity = branches.any((b) => b.bankId == bank.id && b.status == LiquidityStatus.available);
        if (!hasLiquidity) return false;
      }

      return true;
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Tab Switcher
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9), 
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _homeTab = 'ALL');
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _homeTab == 'ALL' 
                            ? (isDark ? const Color(0xFF020617) : Colors.white) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _homeTab == 'ALL' ? [
                          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4)
                        ] : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "جميع المصارف",
                        style: TextStyle(
                          color: _homeTab == 'ALL' ? (isDark ? Colors.white : Colors.black) : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _homeTab = 'FAVORITES');
                    },
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _homeTab == 'FAVORITES' 
                            ? (isDark ? const Color(0xFF020617) : Colors.white) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _homeTab == 'FAVORITES' ? [
                          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4)
                        ] : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "المفضلة",
                        style: TextStyle(
                          color: _homeTab == 'FAVORITES' ? (isDark ? Colors.white : Colors.black) : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Search Bar & Filter Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Filter Button
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0), width: 1),
                ),
                child: IconButton(
                  icon: Icon(Icons.tune, color: isDark ? Colors.white70 : Colors.black54),
                  onPressed: () {
                    _showFilterOptions(context);
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Search Input
              Expanded(
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textAlign: TextAlign.start,
                    decoration: InputDecoration(
                      hintText: "ابحث عن مصرف أو مدينة...",
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _isSearching 
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : (_searchController.text.isNotEmpty 
                            ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: _clearSearch) 
                            : null),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        _buildCurrencyWidget(),

        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: filteredBanks.length,
            itemBuilder: (ctx, idx) {
              final bank = filteredBanks[idx];
              final isFav = favorites.contains(bank.id);

              return OpenContainer(
                transitionType: ContainerTransitionType.fade,
                openBuilder: (context, _) => BankDetailsScreen(bank: bank),
                closedElevation: 0,
                closedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                closedColor: Theme.of(context).cardColor,
                closedBuilder: (context, openContainer) => GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    openContainer();
                  },
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : null),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(favoritesProvider.notifier)
                                  .toggleFavorite(bank.id);
                            },
                          ),
                        ),
                        CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(bank.logoUrl)),
                        const SizedBox(height: 10),
                        Text(bank.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(bank.city,
                            style:
                                const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("خيارات التصفية", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedCity,
              decoration: InputDecoration(
                labelText: "المدينة",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _cities
                  .map((city) => DropdownMenuItem(
                      value: city,
                      child: Text(city)))
                  .toList(),
              onChanged: (v) {
                setState(() => _selectedCity = v!);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text("السيولة المتوفرة فقط"),
              value: _showAvailableOnly,
              onChanged: (v) {
                setState(() => _showAvailableOnly = v);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyWidget() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          CurrencyItem(label: "الدولار (رسمي)", buy: "4.82", sell: "4.84"),
          VerticalDivider(),
          CurrencyItem(label: "الدولار (موازي)", buy: "7.15", sell: "7.18"),
        ],
      ),
    );
  }

  Widget _buildEmergencyContacts() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _emergencyContacts.length,
      itemBuilder: (context, index) {
        final contact = _emergencyContacts[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.phone, color: Colors.green),
            title: Text(contact['name']!, textAlign: TextAlign.start),
            subtitle: Text(contact['number']!, textAlign: TextAlign.start),
            trailing: IconButton(
              icon: const Icon(Icons.call, color: Colors.blue),
              onPressed: () async {
                HapticFeedback.lightImpact();
                final Uri launchUri =
                    Uri(scheme: 'tel', path: contact['number']);
                await launchUrl(launchUri);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfile() {
    final reportCount = ref.watch(reportCountProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Center(
          child: Column(
            children: [
              CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
              SizedBox(height: 10),
              Text("المستخدم التجريبي", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text("user@example.com", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 30),
        ListTile(
          leading: const Icon(Icons.analytics_outlined),
          title: const Text("عدد البلاغات"),
          trailing: Text(reportCount.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text("إعدادات الحساب"),
          onTap: () { HapticFeedback.lightImpact(); },
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text("التنبيهات"),
          onTap: () { HapticFeedback.lightImpact(); },
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text("حول التطبيق"),
          trailing: const Text("v1.0.0"),
          onTap: () { HapticFeedback.lightImpact(); },
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            HapticFeedback.heavyImpact();
            setState(() => _view = 'AUTH');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.withAlpha(20), 
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
          child: const Text("تسجيل الخروج"),
        )
      ],
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, textAlign: TextAlign.center), 
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 100, left: 24, right: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
  }
}

// Separate Screen Widget for better performance during OpenContainer transition
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
      appBar: AppBar(title: Text(bank.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("توجه السيولة (آخر 7 أيام)", 
              textAlign: TextAlign.start,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          const LiquidityChart(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.auto_awesome, color: Colors.orange),
                  SizedBox(width: 8),
                  Text("تحليل الذكاء الاصطناعي",
                      style: TextStyle(fontWeight: FontWeight.bold))
                ]),
                const SizedBox(height: 10),
                aiAnalysis.when(
                  data: (text) => Text(text ??
                      "اضغط للتحليل للحصول على ملخص ذكي لحالة السيولة.",
                      textAlign: TextAlign.start),
                  loading: () => const ShimmerLoading(),
                  error: (err, stack) => const Text("حدث خطأ في التحليل", textAlign: TextAlign.start),
                ),
                if (!aiAnalysis.isLoading && aiAnalysis.value == null)
                  TextButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ref.read(aiAnalysisProvider.notifier).runAnalysis();
                    },
                    child: const Text("تحليل السيولة الآن"),
                  )
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("الفروع",
              textAlign: TextAlign.start,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ...bankBranches.map((branch) => BranchCard(
                branch: branch,
                onReport: (b) => showReportDialog(context, b, (id, status) {
                  HapticFeedback.mediumImpact();
                  ref
                      .read(branchesProvider.notifier)
                      .updateBranchStatus(id, status);
                  ref.read(reportCountProvider.notifier).increment();
                  
                  // Visual confirmation Toast
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("شكراً لمساهمتك! تم تحديث حالة السيولة.", textAlign: TextAlign.center),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.only(bottom: 100, left: 24, right: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }),
              ))
        ],
      ),
    );
  }
}

class CurrencyItem extends StatelessWidget {
  final String label;
  final String buy;
  final String sell;
  const CurrencyItem(
      {super.key, required this.label, required this.buy, required this.sell});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Row(
          children: [
            Text("شراء: $buy",
                style: const TextStyle(fontSize: 11, color: Colors.green)),
            const SizedBox(width: 8),
            Text("بيع: $sell",
                style: const TextStyle(fontSize: 11, color: Colors.red)),
          ],
        )
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
      baseColor: isDark ? const Color(0xFF1E293B) : Colors.grey[300]!,
      highlightColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 12, width: double.infinity, color: Colors.white),
          const SizedBox(height: 8),
          Container(height: 12, width: 200, color: Colors.white),
        ],
      ),
    );
  }
}
