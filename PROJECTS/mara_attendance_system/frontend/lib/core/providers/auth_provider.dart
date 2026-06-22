import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

// Re-export AppUser so existing imports of auth_provider.dart still work
export '../services/auth_service.dart' show AppUser;

// ---------------------------------------------------------------------------
// authServiceProvider — singleton accessor for the AuthService
// ---------------------------------------------------------------------------

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

// ---------------------------------------------------------------------------
// appUserProvider — streams the current AppUser based on Firebase auth state.
//
// Yields null  →  user is signed out (AuthGate shows LoginPage)
// Yields user  →  user is signed in (AuthGate shows DashboardPage)
// ---------------------------------------------------------------------------

final appUserProvider = StreamProvider<AppUser?>((ref) async* {
  final service = ref.read(authServiceProvider);

  await for (final firebaseUser in service.authStateChanges) {
    if (firebaseUser == null) {
      yield null;
    } else {
      try {
        final appUser = await service.getAppUser(firebaseUser.uid);
        yield appUser;
      } catch (_) {
        yield null;
      }
    }
  }
});

// ---------------------------------------------------------------------------
// authProvider — convenience alias that returns the current AppUser synchronously.
//
// This is a thin wrapper so that the 20+ existing files that do:
//   final user = ref.watch(authProvider);
// continue to compile without modification.
//
// Returns null while loading or when signed out.
// ---------------------------------------------------------------------------

final authProvider = Provider<AppUser?>((ref) {
  return ref.watch(appUserProvider).value;
});

// ---------------------------------------------------------------------------
// AuthService sign-out helper accessible from UI widgets
// ---------------------------------------------------------------------------

extension AuthProviderExt on WidgetRef {
  Future<void> signOut() => read(authServiceProvider).signOut();
}
