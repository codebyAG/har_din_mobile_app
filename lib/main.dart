import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/services/event_queue.dart';
import 'data/datasources/local/local_store.dart';
import 'data/datasources/remote/har_din_api_client.dart';
import 'data/repositories/content_repository_impl.dart';
import 'presentation/providers/app_language_controller.dart';
import 'presentation/providers/content_view_model.dart';
import 'presentation/providers/custom_design_quota_controller.dart';
import 'presentation/providers/saved_designs_controller.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

/// §8 / APP-CHANGES-01 §4 — flush queued analytics events whenever the
/// app is backgrounded, in addition to the ~20-event and next-open
/// triggers already wired at their call sites (RootShell, EventQueue).
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      EventQueue.instance.flush();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Composition root — the only place data-layer classes are
        // constructed. Everything below only ever sees the domain
        // repository interface or the ViewModel, never these directly.
        Provider<ContentRepositoryImpl>(
          create: (_) => ContentRepositoryImpl(
            api: HarDinApiClient(),
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
        ChangeNotifierProvider<SavedDesignsController>(
          create: (_) => SavedDesignsController(),
        ),
        ChangeNotifierProvider<CustomDesignQuotaController>(
          create: (_) => CustomDesignQuotaController(),
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
