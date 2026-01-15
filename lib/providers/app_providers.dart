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
  final prefs = ref.watch(sharedPreferencesProvider);
  return BanksNotifier(prefs);
});

class BanksNotifier extends StateNotifier<List<Bank>> {
  final SharedPreferences prefs;
  static const String _key = 'banks_persistence';

  BanksNotifier(this.prefs) : super(kDefaultBanks) {
    _loadBanks();
  }

  void _loadBanks() {
    final saved = prefs.getStringList(_key);
    if (saved != null) {
      final loadedBanks = saved.map((e) => Bank.fromJson(e)).toList();
      final defaultIds = kDefaultBanks.map((b) => b.id).toSet();
      
      // Filter out banks that are already in defaults to avoid duplicates
      final newBanks = loadedBanks.where((b) => !defaultIds.contains(b.id)).toList();
      state = [...kDefaultBanks, ...newBanks];
    }
  }

  void addBank(Bank bank) {
    state = [...state, bank];
    _saveBanks();
  }

  void _saveBanks() {
    // Only save banks that are NOT in the default list
    final toSave = state.where((b) => !kDefaultBanks.any((db) => db.id == b.id)).toList();
    prefs.setStringList(_key, toSave.map((b) => b.toJson()).toList());
  }
}

// 2. Provider for Branches
final branchesProvider = StateNotifierProvider<BranchesNotifier, List<Branch>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BranchesNotifier(prefs);
});

class BranchesNotifier extends StateNotifier<List<Branch>> {
  final SharedPreferences prefs;
  static const String _key = 'branches_persistence';

  BranchesNotifier(this.prefs) : super(kDefaultBranches) {
    _loadBranches();
  }

  void _loadBranches() {
    final saved = prefs.getStringList(_key);
    if (saved != null) {
      final loadedBranches = saved.map((e) => Branch.fromJson(e)).toList();
      
      // Create a mutable copy of defaults
      List<Branch> newState = List.from(kDefaultBranches);
      
      for (final loaded in loadedBranches) {
        final index = newState.indexWhere((b) => b.id == loaded.id);
        if (index != -1) {
          // Update default branch with saved state (status, lastUpdate etc)
          newState[index] = loaded;
        } else {
          // Add new branch
          newState.add(loaded);
        }
      }
      state = newState;
    }
  }

  void addBranch(Branch branch) {
    state = [...state, branch];
    _saveBranches();
  }

  void updateBranchStatus(String id, LiquidityStatus status) {
    state = [
      for (final branch in state)
        if (branch.id == id)
          branch.copyWith(status: status, lastUpdate: DateTime.now())
        else
          branch,
    ];
    _saveBranches();
  }

  void _saveBranches() {
    // We save everything because default branches can have updated statuses
    prefs.setStringList(_key, state.map((b) => b.toJson()).toList());
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
