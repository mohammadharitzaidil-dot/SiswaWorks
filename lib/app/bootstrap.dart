import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
  });

  final LocaleController localeController;
  final AuthController authController;

  void dispose() {
    authController.dispose();
    localeController.dispose();
  }
}

/// Composition root. Firebase is never initialized by the root widget.
Future<AppDependencies> bootstrap() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final localeController = LocaleController(
    store: SharedPreferencesLocaleStore(SharedPreferencesAsync()),
  );
  await localeController.load();
  final authController = AuthController(
    repository: FirebaseAuthRepository(FirebaseAuth.instance),
  );
  await authController.start();
  return AppDependencies(
    localeController: localeController,
    authController: authController,
  );
}
