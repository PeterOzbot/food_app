import 'package:sqflite/sqflite.dart';

import 'app_migration.dart';

/// Version 1 — creates the initial meal_entries table.
class V1CreateMealEntries extends AppMigration {
  @override
  int get toVersion => 1;

  @override
  String get description => 'Create meal_entries table';

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE meal_entries (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        date                TEXT    NOT NULL,
        text                TEXT    NOT NULL,

        calories            REAL    NOT NULL,
        protein             REAL    NOT NULL,
        total_fat           REAL    NOT NULL,
        carbohydrates       REAL    NOT NULL,
        dietary_fiber       REAL    NOT NULL,
        sugars              REAL    NOT NULL,

        saturated_fat       REAL,
        trans_fat           REAL,

        vitamin_a           REAL,
        vitamin_c           REAL,
        vitamin_d           REAL,
        vitamin_e           REAL,
        vitamin_k           REAL,
        thiamin_b1          REAL,
        riboflavin_b2       REAL,
        niacin_b3           REAL,
        vitamin_b6          REAL,
        folate_b9           REAL,
        vitamin_b12         REAL,
        pantothenic_acid_b5 REAL,
        biotin_b7           REAL,

        calcium             REAL,
        iron                REAL,
        magnesium           REAL,
        phosphorus          REAL,
        potassium           REAL,
        sodium              REAL,
        zinc                REAL,
        copper              REAL,
        manganese           REAL,
        selenium            REAL,

        cholesterol         REAL,
        water               REAL
      )
    ''');
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS meal_entries');
  }
}

