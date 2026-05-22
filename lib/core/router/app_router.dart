import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gestionbudget/features/admin/presentation/admin_screen.dart';
import 'package:gestionbudget/features/auth/data/auth_service.dart';
import 'package:gestionbudget/features/auth/presentation/login_screen.dart';
import 'package:gestionbudget/features/budget/presentation/budget_screen.dart';
import 'package:gestionbudget/features/dashboard/presentation/dashboard_screen.dart';
import 'package:gestionbudget/features/expenses/presentation/add_expense_screen.dart';
import 'package:gestionbudget/features/expenses/presentation/history_screen.dart';
import 'package:gestionbudget/features/goals/presentation/goals_screen.dart';
import 'package:gestionbudget/features/license/presentation/license_screen.dart';
import 'package:gestionbudget/features/license/providers/license_provider.dart';
import 'package:gestionbudget/features/onboarding/presentation/onboarding_screen.dart';
import 'package:gestionbudget/features/settings/presentation/settings_screen.dart';
import 'package:gestionbudget/features/stats/presentation/stats_screen.dart';
import 'package:gestionbudget/shared/providers/couple_provider.dart';

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue>(authStateProvider,      (_, _) => notifyListeners());
    _ref.listen<AsyncValue>(coupleFutureProvider,   (_, _) => notifyListeners());
    _ref.listen<AsyncValue>(licenseStreamProvider,  (_, _) => notifyListeners());
  }

  bool    get _authLoading    => _ref.read(authStateProvider).isLoading;
  bool    get _coupleLoading  => _ref.read(coupleFutureProvider).isLoading;
  bool    get _licenseLoading => _ref.read(licenseStreamProvider).isLoading;
  bool    get isLoggedIn      => _ref.read(authStateProvider).asData?.value != null;
  String? get coupleId        => _ref.read(coupleFutureProvider).asData?.value;
  bool    get hasLicense      => _ref.read(licenseStreamProvider).asData?.value ?? false;

  String? redirect(String location) {
    if (_authLoading) return null;

    // Pas connecté → login
    if (!isLoggedIn) {
      return location == '/login' ? null : '/login';
    }

    // Connecté sur /login → rediriger
    if (location == '/login') {
      if (_coupleLoading) return null;
      if (coupleId == null) return '/onboarding';
      if (_licenseLoading) return null;
      return hasLicense ? '/dashboard' : '/license';
    }

    if (_coupleLoading) return null;

    // Pas de couple → onboarding
    if (coupleId == null) {
      return location == '/onboarding' ? null : '/onboarding';
    }

    if (_licenseLoading) return null;

    // Pas de licence valide → écran licence
    if (!hasLicense) {
      return location == '/license' ? null : '/license';
    }

    // Licence OK : sortir des écrans non applicables
    if (location == '/license' || location == '/onboarding') {
      return '/dashboard';
    }

    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: notifier,
    redirect: (context, state) => notifier.redirect(state.matchedLocation),
    routes: [
      GoRoute(path: '/login',       builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/onboarding',  builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/license',     builder: (_, _) => const LicenseScreen()),
      GoRoute(path: '/dashboard',   builder: (_, _) => const DashboardScreen()),
      GoRoute(path: '/add-expense', builder: (_, _) => const AddExpenseScreen()),
      GoRoute(path: '/history',     builder: (_, _) => const HistoryScreen()),
      GoRoute(path: '/stats',       builder: (_, _) => const StatsScreen()),
      GoRoute(path: '/budget',      builder: (_, _) => const BudgetScreen()),
      GoRoute(path: '/goals',       builder: (_, _) => const GoalsScreen()),
      GoRoute(path: '/settings',    builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/admin',       builder: (_, _) => const AdminScreen()),
    ],
  );
});
