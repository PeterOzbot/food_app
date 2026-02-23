import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations/app_migration.dart';
import 'migrations/v1_create_meal_entries.dart';

/// Opens the SQLite database and applies pending migrations automatically.
///
/// Add new [AppMigration] subclasses to [_migrations] in ascending version
/// order, then bump [_currentVersion] to match the highest toVersion.
class AppDatabase {
  static const _dbName = 'food_app.db';
  static const _currentVersion = 1;

  static final List<AppMigration> _migrations = [
    V1CreateMealEntries(),
    // V2SomeChange(),  ← append future migrations here
  ];

  Future<Database> open() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _currentVersion,
      onCreate: (db, version) async {
        for (final m in _migrations) {
          await m.up(db);
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        final pending = _migrations
            .where(
              (m) => m.toVersion > oldVersion && m.toVersion <= newVersion,
            )
            .toList()
          ..sort((a, b) => a.toVersion.compareTo(b.toVersion));
        for (final m in pending) {
          await m.up(db);
        }
      },
      onDowngrade: (db, oldVersion, newVersion) async {
        final toRollback = _migrations
            .where(
              (m) => m.toVersion <= oldVersion && m.toVersion > newVersion,
            )
            .toList()
          ..sort((a, b) => b.toVersion.compareTo(a.toVersion));
        for (final m in toRollback) {
          await m.down(db);
        }
      },
    );
  }
}

