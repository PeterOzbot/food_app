import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'presentation/providers/database_provider.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wait for the database to be ready before showing the app.
    final dbState = ref.watch(databaseProvider);

    return dbState.when(
      loading: () => const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Database failed to open:\n$e',
                textAlign: TextAlign.center),
          ),
        ),
      ),
      data: (_) => MaterialApp.router(
        title: 'Food Tracker',
        routerConfig: appRouter,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.green,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.green,
          brightness: Brightness.dark,
        ),
      ),
    );
  }
}

