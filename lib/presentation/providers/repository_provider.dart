import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/meal_entry_repository.dart';
import '../../data/repositories/sqlite_meal_entry_repository.dart';
import 'database_provider.dart';

final repositoryProvider = Provider<MealEntryRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return dbAsync.when(
    data: (db) => SqliteMealEntryRepository(db),
    loading: () => throw StateError('Database is not ready yet'),
    error: (e, _) => throw StateError('Database error: $e'),
  );
});

