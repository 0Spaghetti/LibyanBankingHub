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
        colorSchemeSeed: Colors.green,
        appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Color(0xFF1E1E1E),
          centerTitle: true,
        ),
        cardTheme: const CardThemeData(
          surfaceTintColor: Colors.transparent,
          color: Color(0xFF1E1E1E),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1E1E),
          onSurface: const Color(0xFFE0E0E0),
          primary: Colors.green[400]!,
          secondary: Colors.greenAccent[700]!,
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
  String _homeTab = 'ALL';
  String _selectedCity = 'الكل';

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("دليلي المصرفي", style: TextStyle(fontWeight: FontWeight.bold)),
            if (reportCount >= 3)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.verified, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text("موثوق",
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              )
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () {
              HapticFeedback.mediumImpact();
              widget.toggleTheme();
            },
          ),
          if (_view != 'MAP')
            IconButton(
                icon: const Icon(Icons.map),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _view = 'MAP');
                }),
        ],
      ),
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        reverse: _view == 'HOME',
        transitionBuilder: (child, animation, secondaryAnimation) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
        child: _buildBody(),
      ),
      bottomNavigationBar: NavigationBar(
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
          NavigationDestination(icon: Icon(Icons.home), label: "الرئيسية"),
          NavigationDestination(icon: Icon(Icons.map), label: "الخريطة"),
          NavigationDestination(icon: Icon(Icons.add), label: "إضافة"),
          NavigationDestination(icon: Icon(Icons.phone), label: "طوارئ"),
          NavigationDestination(icon: Icon(Icons.person), label: "حسابي"),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_view) {
      case 'MAP':
        return BranchMap(branches: ref.watch(branchesProvider));
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
      return true;
    }).toList();

    return Column(
      children: [
        _buildCurrencyWidget(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  onChanged: (v) => setState(() => _searchTerm = v),
                  textAlign: TextAlign.start,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: "ابحث عن مصرف أو عنوان...",
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCity,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                  ),
                  items: _cities
                      .map((city) => DropdownMenuItem(
                          value: city,
                          child: Text(city, style: const TextStyle(fontSize: 12))))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCity = v!),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
                child: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _homeTab = 'ALL');
                    },
                    child: Text("الكل",
                        style: TextStyle(
                            fontWeight: _homeTab == 'ALL'
                                ? FontWeight.bold
                                : FontWeight.normal)))),
            Expanded(
                child: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _homeTab = 'FAVORITES');
                    },
                    child: Text("المفضلة",
                        style: TextStyle(
                            fontWeight: _homeTab == 'FAVORITES'
                                ? FontWeight.bold
                                : FontWeight.normal)))),
          ],
        ),
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

  Widget _buildCurrencyWidget() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.green[900]!.withAlpha(100) : Colors.green.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.green[700]! : Colors.green.withAlpha(50)),
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
            backgroundColor: Colors.red[900]!.withAlpha(50), 
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
        SnackBar(content: Text(msg, textAlign: TextAlign.center), backgroundColor: Colors.green));
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
              color: isDarkMode ? Colors.green[900]!.withAlpha(100) : Theme.of(context).primaryColor.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDarkMode ? Colors.green[700]! : Theme.of(context)
                      .primaryColor
                      .withAlpha((255 * 0.3).round())),
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
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
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
