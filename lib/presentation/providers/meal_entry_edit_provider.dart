import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/meal_entry_model.dart';
import 'repository_provider.dart';

/// Transient state held while the user is editing (or creating) a MealEntry.
class MealEntryEditState {
  MealEntryEditState({
    this.original,
    required this.entry,
    this.isInitializing = true,
    this.isSaving = false,
    this.saveError,
  });

  final MealEntry? original; // null when creating a new entry
  final MealEntry entry;
  final bool isInitializing; // true until init() completes
  final bool isSaving;
  final String? saveError;

  bool get isDirty => entry != original;
  bool get isNew => original == null;

  MealEntryEditState copyWith({
    MealEntry? entry,
    bool? isInitializing,
    bool? isSaving,
    String? saveError,
  }) =>
      MealEntryEditState(
        original: original,
        entry: entry ?? this.entry,
        isInitializing: isInitializing ?? this.isInitializing,
        isSaving: isSaving ?? this.isSaving,
        saveError: saveError,
      );
}

class MealEntryEditNotifier extends Notifier<MealEntryEditState> {
  @override
  MealEntryEditState build() {
    // Default state — overridden by init() before first render.
    return MealEntryEditState(
      entry: MealEntry(
        date: DateTime.now(),
        text: '',
        calories: 0,
        protein: 0,
        totalFat: 0,
        carbohydrates: 0,
        dietaryFiber: 0,
        sugars: 0,
      ),
    );
  }

  /// Call once when the screen opens.
  void init({MealEntry? existing, DateTime? date}) {
    if (existing != null) {
      state = MealEntryEditState(
        original: existing,
        entry: existing,
        isInitializing: false,
      );
    } else {
      final newEntry = MealEntry(
        date: date ?? DateTime.now(),
        text: '',
        calories: 0,
        protein: 0,
        totalFat: 0,
        carbohydrates: 0,
        dietaryFiber: 0,
        sugars: 0,
      );
      state = MealEntryEditState(entry: newEntry, isInitializing: false);
    }
  }

  void update(MealEntry updated) {
    state = state.copyWith(entry: updated);
  }

  Future<bool> save() async {
    state = state.copyWith(isSaving: true);
    try {
      final repo = ref.read(repositoryProvider);
      if (state.isNew) {
        await repo.insert(state.entry);
      } else {
        await repo.update(state.entry);
      }
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, saveError: e.toString());
      return false;
    }
  }
}

final mealEntryEditProvider =
    NotifierProvider.autoDispose<MealEntryEditNotifier, MealEntryEditState>(
  MealEntryEditNotifier.new,
);

