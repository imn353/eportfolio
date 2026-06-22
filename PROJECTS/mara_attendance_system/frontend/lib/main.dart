import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.initialize();

  // ── Global error logging ─────────────────────────────────────────────────
  // Catches Flutter framework errors (widget build errors, etc.)
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('\n[FLUTTER ERROR] ══════════════════════════════════');
    debugPrint('  ${details.exceptionAsString()}');
    debugPrint('  ${details.stack?.toString().split('\n').take(8).join('\n  ')}');
    debugPrint('══════════════════════════════════════════════════\n');
    FlutterError.presentError(details); // also show red screen in debug
  };

  // Catches async errors not caught by Flutter framework (Firestore, etc.)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('\n[ASYNC ERROR] ═══════════════════════════════════');
    debugPrint('  $error');
    debugPrint('  ${stack.toString().split('\n').take(8).join('\n  ')}');
    debugPrint('═════════════════════════════════════════════════\n');
    return true; // handled
  };

  runApp(
    const ProviderScope(
      child: MaraAttendanceApp(),
    ),
  );
}
