import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/datasources/local/local_store.dart';
import 'data/datasources/remote/har_din_api_client.dart';
import 'data/repositories/content_repository_impl.dart';
import 'presentation/providers/app_language_controller.dart';
import 'presentation/providers/content_view_model.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Composition root — the only place data-layer classes are
        // constructed. Everything below only ever sees the domain
        // repository interface or the ViewModel, never these directly.
        Provider<ContentRepositoryImpl>(
          create: (_) => ContentRepositoryImpl(
            api: const HarDinApiClient(),
            store: const LocalStore(),
          ),
        ),
        ChangeNotifierProvider<ContentViewModel>(
          create: (context) =>
              ContentViewModel(context.read<ContentRepositoryImpl>()),
        ),
        ChangeNotifierProvider<AppLanguageController>(
          create: (_) => AppLanguageController(),
        ),
      ],
      child: MaterialApp(
        title: 'हर दिन',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}
