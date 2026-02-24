import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:food_app/data/models/meal_entry_model.dart';
import 'package:food_app/data/repositories/sqlite_meal_entry_repository.dart';

void main() {
  // Initialize FFI for desktop testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late SqliteMealEntryRepository repository;

  setUp(() async {
    // Create in-memory database for each test
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE meal_entries (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL,
              text TEXT NOT NULL,
              calories REAL NOT NULL,
              protein REAL NOT NULL,
              total_fat REAL NOT NULL,
              carbohydrates REAL NOT NULL,
              dietary_fiber REAL NOT NULL,
              sugars REAL NOT NULL,
              saturated_fat REAL,
              trans_fat REAL,
              vitamin_a REAL,
              vitamin_c REAL,
              vitamin_d REAL,
              vitamin_e REAL,
              vitamin_k REAL,
              thiamin_b1 REAL,
              riboflavin_b2 REAL,
              niacin_b3 REAL,
              vitamin_b6 REAL,
              folate_b9 REAL,
              vitamin_b12 REAL,
              pantothenic_acid_b5 REAL,
              biotin_b7 REAL,
              calcium REAL,
              iron REAL,
              magnesium REAL,
              phosphorus REAL,
              potassium REAL,
              sodium REAL,
              zinc REAL,
              copper REAL,
              manganese REAL,
              selenium REAL,
              cholesterol REAL,
              water REAL
            )
          ''');
        },
      ),
    );
    repository = SqliteMealEntryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SqliteMealEntryRepository', () {
    final testEntry = MealEntry(
      date: DateTime(2024, 2, 24, 12, 0),
      text: 'Test meal',
      calories: 500,
      protein: 30,
      totalFat: 20,
      carbohydrates: 50,
      dietaryFiber: 5,
      sugars: 10,
    );

    test('insert() creates new entry and returns it with id', () async {
      final inserted = await repository.insert(testEntry);

      expect(inserted.id, isNotNull);
      expect(inserted.id, greaterThan(0));
      expect(inserted.text, equals('Test meal'));
      expect(inserted.calories, equals(500));
    });

    test('insert() creates entry without id in database', () async {
      // Entry with no id
      expect(testEntry.id, isNull);

      final inserted = await repository.insert(testEntry);

      // Now has an id
      expect(inserted.id, isNotNull);

      // Verify in database
      final rows = await db.query('meal_entries', where: 'id = ?', whereArgs: [inserted.id]);
      expect(rows.length, equals(1));
      expect(rows.first['text'], equals('Test meal'));
    });

    test('update() modifies existing entry', () async {
      // First insert
      final inserted = await repository.insert(testEntry);
      expect(inserted.id, isNotNull);

      // Modify and update
      final modified = inserted.copyWith(text: 'Modified meal', calories: 600);
      await repository.update(modified);

      // Verify in database
      final rows = await db.query('meal_entries', where: 'id = ?', whereArgs: [inserted.id]);
      expect(rows.length, equals(1));
      expect(rows.first['text'], equals('Modified meal'));
      expect(rows.first['calories'], equals(600));
    });

    test('update() changes date on existing entry', () async {
      // Insert entry for Feb 24
      final inserted = await repository.insert(testEntry);
      final originalId = inserted.id!;

      // Change date to March 1
      final newDate = DateTime(2024, 3, 1, 12, 0);
      final modified = inserted.copyWith(date: newDate);
      await repository.update(modified);

      // Verify: same id, new date
      final rows = await db.query('meal_entries', where: 'id = ?', whereArgs: [originalId]);
      expect(rows.length, equals(1));
      expect(rows.first['id'], equals(originalId));
      expect(DateTime.parse(rows.first['date'] as String).day, equals(1));
      expect(DateTime.parse(rows.first['date'] as String).month, equals(3));
    });

    test('update() with null id throws assertion error', () async {
      final entryWithoutId = MealEntry(
        date: DateTime(2024, 2, 24),
        text: 'No id',
        calories: 100,
        protein: 10,
        totalFat: 5,
        carbohydrates: 10,
        dietaryFiber: 1,
        sugars: 2,
      );

      expect(entryWithoutId.id, isNull);
      expect(
        () => repository.update(entryWithoutId),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

