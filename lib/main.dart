import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
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
    const primaryEmerald = Color(0xFF10B981);
    
    return MaterialApp(
      title: 'دليلي المصرفي',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.tajawalTextTheme(ThemeData.light().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryEmerald,
          primary: primaryEmerald,
          surface: Colors.white,
          onSurface: const Color(0xFF111827),
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFF3F4F6)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryEmerald,
          brightness: Brightness.dark,
          primary: primaryEmerald,
          surface: const Color(0xFF1F2937), // Lighter navy component
          onSurface: const Color(0xFFF9FAFB),
        ),
        scaffoldBackgroundColor: const Color(0xFF111827), // blue-grey background
        appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1F2937),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF374151)),
          ),
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "دليلي المصرفي",
          style: TextStyle(
            color: Color(0xFF10B981),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.toggleTheme();
              },
              borderRadius: BorderRadius.circular(100),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFF4F4F5),
                  shape: BoxShape.circle,
                ),
                child: Icon(isDark
                    ? Icons.wb_sunny_outlined
                    : Icons.dark_mode_outlined, size: 20),
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
        height: 90,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937).withOpacity(0.95) : Colors.white.withOpacity(0.95),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(isDark ? 40 : 10), blurRadius: 20, offset: const Offset(0, -5))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, "المصارف", _view == 'HOME' || _view == 'DETAILS'),
            _buildNavItem(1, Icons.map_rounded, "الخريطة", _view == 'MAP'),
            _buildNavItem(2, Icons.add_circle_rounded, "إضافة", _view == 'ADD'),
            _buildNavItem(3, Icons.phone_rounded, "طوارئ", _view == 'EMERGENCY'),
            _buildNavItem(4, Icons.person_rounded, "حسابي", _view == 'PROFILE'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int idx, IconData icon, String label, bool isSelected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(0xFF10B981);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (idx == 0) _view = 'HOME';
          if (idx == 1) _view = 'MAP';
          if (idx == 2) _view = 'ADD';
          if (idx == 3) _view = 'EMERGENCY';
          if (idx == 4) _view = 'PROFILE';
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, isSelected ? -8 : 0, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSelected ? 1.2 : 1.0,
              child: Icon(
                icon,
                color: isSelected ? primary : (isDark ? Colors.grey[600] : Colors.grey[400]),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primary : (isDark ? Colors.grey[600] : Colors.grey[400]),
              ),
            ),
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
        // Check if any of its branches matches the address or name
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFF4F4F5), 
              borderRadius: BorderRadius.circular(100),
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
                            ? (isDark ? const Color(0xFF111827) : Colors.white) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: _homeTab == 'ALL' ? [
                          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4)
                        ] : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "جميع المصارف",
                        style: TextStyle(
                          color: _homeTab == 'ALL' ? (isDark ? Colors.white : Colors.black) : Colors.grey[500],
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
                            ? (isDark ? const Color(0xFF111827) : Colors.white) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: _homeTab == 'FAVORITES' ? [
                          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4)
                        ] : [],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "المفضلة",
                        style: TextStyle(
                          color: _homeTab == 'FAVORITES' ? (isDark ? Colors.white : Colors.black) : Colors.grey[500],
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

        // Search Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Filter Button
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE4E4E7)),
                ),
                child: IconButton(
                  icon: Icon(Icons.tune_rounded, color: isDark ? Colors.white70 : Colors.black54),
                  onPressed: () => _showFilterOptions(context),
                ),
              ),
              const SizedBox(width: 12),
              // Search Field
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 55,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F2937) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isSearchFocused 
                        ? const Color(0xFF10B981) 
                        : (isDark ? const Color(0xFF374151) : const Color(0xFFE4E4E7)),
                      width: _isSearchFocused ? 2 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    textAlign: TextAlign.start,
                    decoration: InputDecoration(
                      hintText: "ابحث عن مصرف أو مدينة...",
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                      suffixIcon: _isSearching 
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : (_searchController.text.isNotEmpty 
                            ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: _clearSearch) 
                            : const Icon(Icons.search_rounded, color: Colors.grey)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
                crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8),
            itemCount: filteredBanks.length,
            itemBuilder: (ctx, idx) {
              final bank = filteredBanks[idx];
              final isFav = favorites.contains(bank.id);

              return OpenContainer(
                transitionType: ContainerTransitionType.fade,
                openBuilder: (context, _) => BankDetailsScreen(bank: bank),
                closedElevation: 0,
                closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                closedColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                closedBuilder: (context, openContainer) => GestureDetector(
                  onTap: openContainer,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8,
                          left: 8,
                          child: InkWell(
                            onTap: () => ref.read(favoritesProvider.notifier).toggleFavorite(bank.id),
                            borderRadius: BorderRadius.circular(100),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.black.withAlpha(10), shape: BoxShape.circle),
                              child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFav ? Colors.red : (isDark ? Colors.white70 : Colors.black26), size: 18),
                            ),
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFF4F4F5), width: 2)
                                ),
                                child: CircleAvatar(
                                  radius: 35,
                                  backgroundColor: Colors.white,
                                  backgroundImage: NetworkImage(bank.logoUrl),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(bank.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.black.withAlpha(40) : const Color(0xFFF4F4F5), 
                                  borderRadius: BorderRadius.circular(100)
                                ),
                                child: Text(bank.city, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ),
                            ],
                          ),
                        ),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("خيارات التصفية", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _selectedCity,
              decoration: InputDecoration(
                labelText: "المدينة",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              items: _cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
              onChanged: (v) {
                setState(() => _selectedCity = v!);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text("السيولة المتوفرة فقط"),
              activeColor: const Color(0xFF10B981),
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

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg, textAlign: TextAlign.center), 
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 110, left: 24, right: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ));
  }

  Widget _buildEmergencyContacts() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _emergencyContacts.length,
      itemBuilder: (context, index) {
        final contact = _emergencyContacts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF10B981)),
            title: Text(contact['name']!, textAlign: TextAlign.start, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(contact['number']!, textAlign: TextAlign.start),
            trailing: Container(
              decoration: BoxDecoration(color: const Color(0xFF10B981).withAlpha(20), shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.call_rounded, color: Color(0xFF10B981)),
                onPressed: () async {
                  final Uri launchUri = Uri(scheme: 'tel', path: contact['number']);
                  await launchUrl(launchUri);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfile() {
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
          onPressed: () => setState(() => _view = 'AUTH'),
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

  Widget _buildCurrencyWidget() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE4E4E7)),
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
}

// Separate Screen Widget
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
              border: Border.all(color: isDarkMode ? const Color(0xFF374151) : const Color(0xFFE4E4E7)),
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
