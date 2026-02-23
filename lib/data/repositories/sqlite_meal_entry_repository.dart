import 'package:sqflite/sqflite.dart';

import '../../domain/entities/day_summary.dart';
import '../models/meal_entry_model.dart';
import 'meal_entry_repository.dart';

class SqliteMealEntryRepository implements MealEntryRepository {
  SqliteMealEntryRepository(this._db);

  final Database _db;
  static const _table = 'meal_entries';

  // ── getDaySummaries ────────────────────────────────────────────────────

  @override
  Future<List<DaySummary>> getDaySummaries() async {
    final rows = await _db.rawQuery('''
      SELECT
        date(date)          AS day,
        COUNT(*)            AS entry_count,
        SUM(calories)       AS total_calories,
        SUM(protein)        AS total_protein,
        SUM(total_fat)      AS total_fat,
        SUM(carbohydrates)  AS total_carbohydrates
      FROM $_table
      GROUP BY date(date)
      ORDER BY day DESC
    ''');

    return rows.map((r) {
      final dayStr = r['day'] as String;
      return DaySummary(
        date: DateTime.parse(dayStr),
        entryCount: (r['entry_count'] as int?) ?? 0,
        totalCalories: (r['total_calories'] as num?)?.toDouble() ?? 0,
        totalProtein: (r['total_protein'] as num?)?.toDouble() ?? 0,
        totalFat: (r['total_fat'] as num?)?.toDouble() ?? 0,
        totalCarbohydrates: (r['total_carbohydrates'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  // ── getEntriesForDate ──────────────────────────────────────────────────

  @override
  Future<List<MealEntry>> getEntriesForDate(DateTime date) async {
    final rows = await _db.query(
      _table,
      where: "date(date) = date(?)",
      whereArgs: [date.toIso8601String()],
      orderBy: 'id ASC',
    );
    return rows.map(MealEntry.fromMap).toList();
  }

  // ── insert ─────────────────────────────────────────────────────────────

  @override
  Future<MealEntry> insert(MealEntry entry) async {
    final map = entry.toMap()..remove('id');
    final id = await _db.insert(_table, map);
    return entry.copyWith(id: id);
  }

  // ── update ─────────────────────────────────────────────────────────────

  @override
  Future<void> update(MealEntry entry) async {
    assert(entry.id != null, 'Cannot update an entry without an id');
    await _db.update(
      _table,
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  // ── delete ─────────────────────────────────────────────────────────────

  @override
  Future<void> delete(int id) async {
    await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}

