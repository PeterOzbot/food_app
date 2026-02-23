import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/day_summary.dart';
import 'repository_provider.dart';

class MealListNotifier extends AsyncNotifier<List<DaySummary>> {
  @override
  Future<List<DaySummary>> build() async {
    final repo = ref.watch(repositoryProvider);
    return repo.getDaySummaries();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(repositoryProvider).getDaySummaries(),
    );
  }
}

final mealListProvider =
    AsyncNotifierProvider<MealListNotifier, List<DaySummary>>(
  MealListNotifier.new,
);

