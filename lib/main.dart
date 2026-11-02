import 'package:flutter/widgets.dart';

import 'app/bootstrap.dart';
import 'app/main_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dependencies = await bootstrap();
  runApp(
    MainApp(
      localeController: dependencies.localeController,
      authController: dependencies.authController,
    ),
  );
}
