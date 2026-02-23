import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/meal_entry_model.dart';
import 'repository_provider.dart';

/// Riverpod 3.x family async notifier — arg is passed via constructor.
class DayDetailNotifier extends AsyncNotifier<List<MealEntry>> {
  DayDetailNotifier(this.date);

  final DateTime date;

  @override
  Future<List<MealEntry>> build() async {
    final repo = ref.watch(repositoryProvider);
    return repo.getEntriesForDate(date);
  }

  Future<void> delete(int id) async {
    await ref.read(repositoryProvider).delete(id);
    state = AsyncData(
      await ref.read(repositoryProvider).getEntriesForDate(date),
    );
  }
}

final dayDetailProvider =
    AsyncNotifierProvider.family<DayDetailNotifier, List<MealEntry>, DateTime>(
  DayDetailNotifier.new,
);

