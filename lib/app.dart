import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/colors.dart';
import 'screens/navigation_hub.dart';

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
        textTheme: GoogleFonts.tajawalTextTheme(ThemeData.light().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary500,
          primary: AppColors.primary500,
          surface: AppColors.white,
          onSurface: AppColors.gray900,
        ),
        scaffoldBackgroundColor: AppColors.gray50,
        appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.gray100),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary500,
          brightness: Brightness.dark,
          primary: AppColors.primary500,
          surface: AppColors.gray800,
          onSurface: AppColors.gray50,
        ),
        scaffoldBackgroundColor: AppColors.gray900,
        appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.gray800,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.gray700),
          ),
        ),
      ),
      locale: const Locale('ar'),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: NavigationHub(toggleTheme: toggleTheme),
    );
  }
}
