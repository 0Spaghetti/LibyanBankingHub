import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'providers/app_providers.dart';

void main() async {
  // Ensure Flutter bindings are initialized for async setup
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  runApp(
    ProviderScope(
      overrides: [
        // Inject the initialized SharedPreferences into the provider tree
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const LibyanBankingApp(),
    ),
  );
}
