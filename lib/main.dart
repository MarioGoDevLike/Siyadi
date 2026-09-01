import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/theme/app_colors.dart';
import 'data/services/firebase_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.fog,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await bootstrapFirebase();

  runApp(
    const ProviderScope(
      child: SiyadiApp(),
    ),
  );
}
