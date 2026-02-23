import '../../domain/entities/day_summary.dart';
import '../models/meal_entry_model.dart';

/// Abstract interface for all meal-entry persistence operations.
/// The presentation layer depends only on this contract, never on SQLite directly.
abstract class MealEntryRepository {
  /// Returns one [DaySummary] per calendar day that has entries,
  /// sorted descending (most-recent day first).
  Future<List<DaySummary>> getDaySummaries();

  /// Returns every [MealEntry] recorded on the given calendar day.
  Future<List<MealEntry>> getEntriesForDate(DateTime date);

  /// Persists a new entry and returns the saved copy with its assigned [id].
  Future<MealEntry> insert(MealEntry entry);

  /// Overwrites an existing entry matched by [entry.id].
  Future<void> update(MealEntry entry);

  /// Permanently removes the entry with the given [id].
  Future<void> delete(int id);
}

