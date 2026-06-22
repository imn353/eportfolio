import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'features/auth/login_page.dart';
import 'features/auth/pending_approval_page.dart';
import 'features/dashboard/dashboard_page.dart';

class MaraAttendanceApp extends StatelessWidget {
  const MaraAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MARA Attendance System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

/// AuthGate decides what screen to show based on Firebase auth state.
///
/// Loading  → spinner
/// Signed in → DashboardPage
/// Signed out → LoginPage
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(appUserProvider);

    return userAsync.when(
      skipLoadingOnReload: true,   // don't flash spinner during auth transitions
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => const LoginPage(),
      data: (user) {
        if (user == null) {
          return const LoginPage();
        }
        if (user.status == 'pending_approval') {
          return const PendingApprovalPage();
        }
        if (user.status == 'disabled') {
          return const Scaffold(
            body: Center(child: Text('Your account has been disabled.')),
          );
        }
        return const DashboardPage();
      },
    );
  }
}
