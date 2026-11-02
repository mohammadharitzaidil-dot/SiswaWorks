import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/data/firebase_auth_repository.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/settings/data/locale_store.dart';
import '../features/settings/presentation/locale_controller.dart';
import '../firebase_options.dart';

class AppDependencies {
  const AppDependencies({
    required this.localeController,
    required this.authController,
    required this.firestore,
  });

  final LocaleController localeController;
  final AuthController authController;
  final FirebaseFirestore firestore;

  void dispose() {
    authController.dispose();
    localeController.dispose();
  }
}

/// Composition root. Firebase is never initialized by the root widget.
Future<AppDependencies> bootstrap() async {
  const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');

  if (useEmulators && !kDebugMode) {
    throw StateError('Firebase emulator mode requires a debug build.');
  }

  final firebaseApp = useEmulators
      ? await Firebase.initializeApp(demoProjectId: 'demo-siswaworks')
      : await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

  final firebaseAuth = FirebaseAuth.instanceFor(app: firebaseApp);
  final firestore = FirebaseFirestore.instanceFor(app: firebaseApp);

  if (useEmulators) {
    const configuredHost = String.fromEnvironment('FIREBASE_EMULATOR_HOST');
    final host = configuredHost.isNotEmpty
        ? configuredHost
        : !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';

    await firebaseAuth.useAuthEmulator(host, 9099);
    firestore.settings = const Settings(persistenceEnabled: false);
    firestore.useFirestoreEmulator(host, 8080);
  }

  final localeController = LocaleController(
    store: SharedPreferencesLocaleStore(SharedPreferencesAsync()),
  );
  await localeController.load();

  final authController = AuthController(
    repository: FirebaseAuthRepository(firebaseAuth),
  );
  await authController.start();

  return AppDependencies(
    localeController: localeController,
    authController: authController,
    firestore: firestore,
  );
}
