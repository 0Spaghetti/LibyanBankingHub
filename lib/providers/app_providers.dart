import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../data.dart';

// Provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// 1. Provider for Banks
final banksProvider = StateNotifierProvider<BanksNotifier, List<Bank>>((ref) {
  return BanksNotifier();
});

class BanksNotifier extends StateNotifier<List<Bank>> {
  BanksNotifier() : super(kDefaultBanks);

  void addBank(Bank bank) {
    state = [...state, bank];
  }
}

// 2. Provider for Branches
final branchesProvider = StateNotifierProvider<BranchesNotifier, List<Branch>>((ref) {
  return BranchesNotifier();
});

class BranchesNotifier extends StateNotifier<List<Branch>> {
  BranchesNotifier() : super(kDefaultBranches);

  void addBranch(Branch branch) {
    state = [...state, branch];
  }

  void updateBranchStatus(String id, LiquidityStatus status) {
    state = [
      for (final branch in state)
        if (branch.id == id)
          branch.copyWith(status: status, lastUpdate: DateTime.now())
        else
          branch,
    ];
  }
}

// 3. Provider for Favorites
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FavoritesNotifier(prefs);
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  final SharedPreferences prefs;
  static const String _key = 'favorites';

  FavoritesNotifier(this.prefs) : super({}) {
    _loadFavorites();
  }

  void _loadFavorites() {
    final saved = prefs.getStringList(_key);
    if (saved != null) {
      state = saved.toSet();
    }
  }

  void toggleFavorite(String bankId) {
    if (state.contains(bankId)) {
      state = {...state}..remove(bankId);
    } else {
      state = {...state}..add(bankId);
    }
    prefs.setStringList(_key, state.toList());
  }
}

// 4. Provider for AI Analysis
final aiAnalysisProvider = StateNotifierProvider<AINotifier, AsyncValue<String?>>((ref) {
  return AINotifier();
});

class AINotifier extends StateNotifier<AsyncValue<String?>> {
  AINotifier() : super(const AsyncValue.data(null));

  Future<void> runAnalysis() async {
    state = const AsyncValue.loading();
    // Simulate AI call
    await Future.delayed(const Duration(seconds: 2));
    state = const AsyncValue.data("بناءً على البيانات، فرع حي الأندلس هو الأفضل حالياً لقلة الازدحام وتوفر السيولة.");
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

// 5. Provider for User Stats
final reportCountProvider = StateNotifierProvider<ReportCountNotifier, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ReportCountNotifier(prefs);
});

class ReportCountNotifier extends StateNotifier<int> {
  final SharedPreferences prefs;
  static const String _key = 'report_count';

  ReportCountNotifier(this.prefs) : super(0) {
    state = prefs.getInt(_key) ?? 0;
  }

  void increment() {
    state++;
    prefs.setInt(_key, state);
  }
}
