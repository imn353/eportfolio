import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<FirebaseApp> initialize() {
    return Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
