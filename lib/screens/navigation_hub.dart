import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animations/animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../providers/app_providers.dart';
import '../theme/colors.dart';
import 'splash_screen.dart';
import 'onboarding_screen.dart';
import 'auth_screen.dart';
import 'add_data_screen.dart';
import 'bank_details_screen.dart';
import 'profile_screen.dart';
import '../components/branch_map.dart';
import '../components/common_widgets.dart';

class NavigationHub extends ConsumerStatefulWidget {
  final VoidCallback toggleTheme;
  const NavigationHub({super.key, required this.toggleTheme});

  @override
  ConsumerState<NavigationHub> createState() => _NavigationHubState();
}

class _NavigationHubState extends ConsumerState<NavigationHub> {
  String _view = 'SPLASH'; 

  String _searchTerm = '';
  String _homeTab = 'ALL'; 
  String _selectedCity = 'الكل';
  bool _showAvailableOnly = false;
  
  bool _isSearching = false;
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchFocused = false;

  final List<String> _cities = ['الكل', 'طرابلس', 'بنغازي', 'مصراتة', 'الزاوية', 'سبها'];

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
      setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
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
    setState(() => _isSearching = true);
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
    if (_view == 'SPLASH') return SplashScreen(onComplete: () => setState(() => _view = 'ONBOARDING'));
    if (_view == 'ONBOARDING') return OnboardingScreen(onFinish: () => setState(() => _view = 'AUTH'));
    if (_view == 'AUTH') return AuthScreen(onLogin: () => setState(() => _view = 'HOME'));
    
    if (_view == 'ADD') {
      return AddDataScreen(
        banks: ref.watch(banksProvider),
        onCancel: () => setState(() => _view = 'HOME'),
        onAddBank: (b) {
          ref.read(banksProvider.notifier).addBank(b);
        },
        onAddBranch: (b) {
          ref.read(branchesProvider.notifier).addBranch(b);
        },
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("دليلي المصرفي",
          style: TextStyle(
            color: isDark ? AppColors.primary400 : AppColors.primary800, 
            fontWeight: FontWeight.bold, 
            fontSize: 22
          )),
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
                  color: isDark ? AppColors.gray700 : AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(isDark ? 0 : 10), blurRadius: 4)
                  ]
                ),
                child: Icon(isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined, 
                  size: 20, 
                  color: isDark ? Colors.white : AppColors.gray900),
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
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: _buildBody(),
      ),
      bottomNavigationBar: Container(
        height: 90,
        decoration: BoxDecoration(
          color: isDark 
              ? AppColors.gray800.withAlpha((255 * 0.95).round()) 
              : AppColors.white.withAlpha((255 * 0.95).round()),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(isDark ? 40 : 10), blurRadius: 20, offset: const Offset(0, -5))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, "المصارف", _view == 'HOME'),
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
    final primary = AppColors.primary500;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          if (idx == 0) _view = 'HOME';
          else if (idx == 1) _view = 'MAP';
          else if (idx == 2) _view = 'ADD';
          else if (idx == 3) _view = 'EMERGENCY';
          else if (idx == 4) _view = 'PROFILE';
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
              child: Icon(icon, color: isSelected ? primary : (isDark ? AppColors.gray400 : AppColors.gray500)),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              fontSize: 10, 
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
              color: isSelected ? primary : (isDark ? AppColors.gray400 : AppColors.gray500)
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_view) {
      case 'MAP':
        return BranchMap(
          branches: ref.watch(branchesProvider),
          onViewDetails: (branch) {
            final bank = ref.read(banksProvider).firstWhere((b) => b.id == branch.bankId);
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => BankDetailsScreen(bank: bank)));
          },
          onReport: (id, status) {
            ref.read(branchesProvider.notifier).updateBranchStatus(id, status);
            ref.read(reportCountProvider.notifier).increment();
          },
        );
      case 'EMERGENCY': return _buildEmergencyContacts();
      case 'PROFILE': return ProfileScreen(onLogout: () => setState(() => _view = 'AUTH'));
      case 'HOME':
      default: return _buildHome();
    }
  }

  Widget _buildHome() {
    final banks = ref.watch(banksProvider);
    final branches = ref.watch(branchesProvider);
    final favorites = ref.watch(favoritesProvider);

    final filteredBanks = banks.where((bank) {
      if (_homeTab == 'FAVORITES' && !favorites.contains(bank.id)) return false;
      bool matchesSearch = _searchTerm.isEmpty || bank.name.contains(_searchTerm) || branches.any((br) => br.bankId == bank.id && br.address.contains(_searchTerm));
      if (!matchesSearch) return false;
      if (_selectedCity != 'الكل' && bank.city != _selectedCity) return false;
      if (_showAvailableOnly && !branches.any((b) => b.bankId == bank.id && b.status == LiquidityStatus.available)) return false;
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
              color: isDark ? AppColors.gray700 : AppColors.gray100, 
              borderRadius: BorderRadius.circular(100)
            ),
            child: Row(
              children: [
                _buildTab('ALL', 'جميع المصارف', isDark),
                _buildTab('FAVORITES', 'المفضلة', isDark),
              ],
            ),
          ),
        ),

        // Search Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 55, height: 55,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.gray800 : AppColors.white, 
                  borderRadius: BorderRadius.circular(16), 
                  border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray200)
                ),
                child: IconButton(
                  icon: Icon(Icons.tune_rounded, color: isDark ? Colors.white70 : AppColors.gray500), 
                  onPressed: () => _showFilterOptions(context)
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 55,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.gray800 : AppColors.white, 
                    borderRadius: BorderRadius.circular(16), 
                    border: Border.all(
                      color: _isSearchFocused ? AppColors.primary500 : (isDark ? AppColors.gray700 : AppColors.gray200), 
                      width: _isSearchFocused ? 2 : 1
                    )
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    textAlign: TextAlign.start,
                    style: TextStyle(color: isDark ? AppColors.white : AppColors.gray900),
                    decoration: InputDecoration(
                      hintText: "ابحث عن مصرف أو مدينة...", 
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14), 
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.gray500),
                      suffixIcon: _isSearching 
                        ? const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))) 
                        : (_searchController.text.isNotEmpty 
                            ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18), onPressed: _clearSearch) 
                            : null), 
                      border: InputBorder.none, 
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15)
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
              crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8
            ),
            itemCount: filteredBanks.length,
            itemBuilder: (ctx, idx) {
              final bank = filteredBanks[idx];
              final isFav = favorites.contains(bank.id);
              return OpenContainer(
                transitionType: ContainerTransitionType.fade,
                openBuilder: (context, _) => BankDetailsScreen(bank: bank),
                closedElevation: 0, 
                closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                closedColor: isDark ? AppColors.gray800 : AppColors.white,
                closedBuilder: (context, openContainer) => GestureDetector(
                  onTap: openContainer,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 8, left: 8, 
                          child: InkWell(
                            onTap: () => ref.read(favoritesProvider.notifier).toggleFavorite(bank.id), 
                            borderRadius: BorderRadius.circular(100), 
                            child: Container(
                              padding: const EdgeInsets.all(6), 
                              decoration: BoxDecoration(color: Colors.black.withAlpha(10), shape: BoxShape.circle), 
                              child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFav ? Colors.red : (isDark ? Colors.white70 : AppColors.gray400), size: 18)
                            )
                          )
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, 
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4), 
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isDark ? AppColors.gray700 : AppColors.gray100, width: 2)), 
                                child: CircleAvatar(radius: 35, backgroundColor: AppColors.white, backgroundImage: NetworkImage(bank.logoUrl))
                              ), 
                              const SizedBox(height: 16), 
                              Text(bank.name, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? AppColors.white : AppColors.gray900)), 
                              const SizedBox(height: 8), 
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), 
                                decoration: BoxDecoration(color: isDark ? Colors.black.withAlpha(40) : AppColors.gray100, borderRadius: BorderRadius.circular(100)), 
                                child: Text(bank.city, style: const TextStyle(fontSize: 11, color: Colors.grey))
                              )
                            ]
                          )
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

  Widget _buildTab(String id, String label, bool isDark) {
    final isActive = _homeTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _homeTab = id);
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? (isDark ? AppColors.gray800 : AppColors.white) : Colors.transparent, 
            borderRadius: BorderRadius.circular(100), 
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4)] : []
          ),
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(
            color: isActive ? (isDark ? AppColors.white : AppColors.gray900) : AppColors.gray500, 
            fontWeight: FontWeight.bold
          )),
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
        color: isDarkMode ? AppColors.gray800 : AppColors.white, 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: isDarkMode ? AppColors.gray700 : AppColors.gray200)
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround, 
        children: [
          CurrencyItem(label: "الدولار (رسمي)", buy: "4.82", sell: "4.84"), 
          VerticalDivider(), 
          CurrencyItem(label: "الدولار (موازي)", buy: "7.15", sell: "7.18")
        ]
      ),
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
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("خيارات التصفية", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _selectedCity, decoration: InputDecoration(labelText: "المدينة", border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))),
              items: _cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
              onChanged: (v) { setState(() => _selectedCity = v!); Navigator.pop(ctx); },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text("السيولة المتوفرة فقط"), 
              activeColor: AppColors.primary500, 
              value: _showAvailableOnly, 
              onChanged: (v) { setState(() => _showAvailableOnly = v); Navigator.pop(ctx); }
            ),
          ],
        ),
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
          margin: const EdgeInsets.only(bottom: 12), 
          child: ListTile(
            leading: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary500), 
            title: Text(contact['name']!, textAlign: TextAlign.start, style: const TextStyle(fontWeight: FontWeight.bold)), 
            subtitle: Text(contact['number']!, textAlign: TextAlign.start), 
            trailing: Container(
              decoration: BoxDecoration(color: AppColors.primary500.withAlpha(20), shape: BoxShape.circle), 
              child: IconButton(
                icon: const Icon(Icons.call_rounded, color: AppColors.primary500), 
                onPressed: () async { 
                  final Uri launchUri = Uri(scheme: 'tel', path: contact['number']); 
                  await launchUrl(launchUri); 
                }
              )
            )
          )
        );
      },
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center), 
        backgroundColor: AppColors.primary600, 
        behavior: SnackBarBehavior.floating, 
        margin: const EdgeInsets.only(bottom: 110, left: 24, right: 24), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
      )
    );
  }
}
